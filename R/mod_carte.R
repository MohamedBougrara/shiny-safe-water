# mod_carte.R
# World map: one indicator, one residence, one year (animated slider).
# Returns the ISO3 code of the country the user clicks, so that the parent
# can open its profile.

carte_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 300,
      shiny::selectInput(ns("indicateur"), "Indicator",
                         choices = stats::setNames(INDICATEURS, INDICATEURS)),
      shiny::radioButtons(ns("milieu"), "Where", choices = stats::setNames(MILIEUX, MILIEUX)),
      shiny::sliderInput(ns("annee"), "Year", min = ANNEES[1], max = ANNEES[2], value = ANNEES[2],
                         step = 1, sep = "", ticks = FALSE,
                         animate = shiny::animationOptions(
                           interval = 900,
                           # Inline icons, and a name for screen readers (translated by the server).
                           playButton = htmltools::tagList(icone("play-fill", "1.4em"),
                             htmltools::span(id = ns("lecture"), class = "visually-hidden", "Play the years")),
                           pauseButton = htmltools::tagList(icone("pause-fill", "1.4em"),
                             htmltools::span(id = ns("pause"), class = "visually-hidden", "Pause")))),
      shiny::p(class = "note", shiny::textOutput(ns("aide"), inline = TRUE)),
      # Follows the indicator, the area and the year; each country opens its profile.
      htmltools::div(class = "retard",
        htmltools::h2(class = "retard-titre", shiny::textOutput(ns("t_retard"), inline = TRUE)),
        shiny::uiOutput(ns("retard")))
    ),
    bslib::layout_column_wrap(
      width = 1 / 3, fill = FALSE,
      bslib::value_box(shiny::textOutput(ns("t_monde")), shiny::textOutput(ns("v_monde")),
                       showcase = icone("globe2"), theme = "primary"),
      bslib::value_box(shiny::textOutput(ns("t_sans")), shiny::textOutput(ns("v_sans")),
                       showcase = icone("droplet-half"), theme = "danger"),
      bslib::value_box(shiny::textOutput(ns("t_pays")), shiny::textOutput(ns("v_pays")),
                       showcase = icone("clipboard-data"))
    ),
    bslib::card(
      full_screen = TRUE, min_height = 460,
      bslib::card_header(shiny::textOutput(ns("titre"), inline = TRUE)),
      graphique_output(ns("carte"), min_height = "420px"),
      bslib::card_footer(class = "note", shiny::textOutput(ns("source"), inline = TRUE))
    )
  )
}

# annee: the year shared by the map, the ranking and the country profile.
carte_server <- function(id, lang, sombre, annee = shiny::reactiveVal()) {
  shiny::moduleServer(id, function(input, output, session) {

    # The year is shared: moving this slider moves the others, and back.
    shiny::observeEvent(input$annee, annee(input$annee))
    shiny::observeEvent(annee(), {
      if (!identical(annee(), input$annee)) shiny::updateSliderInput(session, "annee", value = annee())
    })

    # Labels follow the language; the selections are kept.
    shiny::observeEvent(lang(), {
      l <- lang()
      shiny::updateSelectInput(session, "indicateur", label = tr("indicator", l),
        choices = stats::setNames(INDICATEURS, vapply(paste0("ind_", INDICATEURS), tr, "", l)),
        selected = input$indicateur)
      shiny::updateRadioButtons(session, "milieu", label = tr("residence", l),
        choices = stats::setNames(MILIEUX, vapply(paste0("res_", MILIEUX), tr, "", l)),
        selected = input$milieu)
      shiny::updateSliderInput(session, "annee", label = tr("year", l))
      session$sendCustomMessage("libelle", list(id = session$ns("lecture"), texte = tr("play", l)))
      session$sendCustomMessage("libelle", list(id = session$ns("pause"), texte = tr("pause", l)))
    })
    output$aide    <- shiny::renderText(tr("map_hint", lang()))
    output$source  <- shiny::renderText(tr("source_short", lang()))
    output$t_monde <- shiny::renderText(tr("world_share", lang()))
    output$t_sans  <- shiny::renderText(tr("people_without", lang()))
    output$t_pays  <- shiny::renderText(tr("countries_data", lang()))
    output$titre <- shiny::renderText({
      paste0(tr(paste0("ind_", input$indicateur), lang()), " · ",
             tr(paste0("res_", input$milieu), lang()), " · ", input$annee)
    })

    # The world figures of the selected year (JMP aggregate, not a sum of
    # countries: the JMP imputes the countries without an estimate).
    monde <- shiny::reactive({
      D$eau[D$eau$code == "WLD" & D$eau$year == input$annee & D$eau$residence == input$milieu, ]
    })
    output$v_monde <- shiny::renderText(fmt_pc(monde()$safely, lang()))
    output$v_sans  <- shiny::renderText(fmt_mds(monde()$without_safe, lang()))

    valeurs <- shiny::reactive({
      shiny::req(input$indicateur, input$milieu, input$annee)
      carte_valeurs(D$eau, input$indicateur, input$milieu, input$annee)
    }) |> shiny::bindCache(input$indicateur, input$milieu, input$annee)

    output$v_pays <- shiny::renderText({
      paste(sum(!is.na(valeurs()$valeur)), "/", nrow(valeurs()))
    })

    output$carte <- render_graphique({
      d <- valeurs(); l <- lang()
      survol <- paste0("<b>", d$area, "</b><br>",
                       ifelse(is.na(d$valeur), tr("no_estimate", l), fmt_pc(d$valeur, l)),
                       "<br>", nom_groupe(d$continent, l))
      surface <- input$indicateur == "surface"
      echelle <- if (surface) lapply(seq_along(ECHELLE_CARTE), function(i)
        list(ECHELLE_CARTE[[i]][[1]], ECHELLE_CARTE[[length(ECHELLE_CARTE) - i + 1]][[2]])) else ECHELLE_CARTE
      zmax <- if (surface) max(30, ceiling(max(d$valeur, na.rm = TRUE))) else 100
      trait <- if (isTRUE(sombre())) "#0b1120" else "#ffffff"
      fond <- if (isTRUE(sombre())) "#2F3D55" else "#D7DEE7"
      ok <- !is.na(d$valeur)
      figure(
        list(
          # Grey layer under the data: countries without a national estimate.
          trace(type = "choropleth", geojson = "monde", featureidkey = "id", locations = d$code,
                z = rep(1, nrow(d)), customdata = d$code, text = survol, hoverinfo = "text",
                colorscale = list(list(0, fond), list(1, fond)), showscale = FALSE,
                marker = list(line = list(color = trait, width = 0.5))),
          trace(type = "choropleth", geojson = "monde", featureidkey = "id", locations = d$code[ok],
                z = round(d$valeur[ok], 1), customdata = d$code[ok], text = survol[ok], hoverinfo = "text",
                colorscale = echelle, zmin = 0, zmax = zmax,
                marker = list(line = list(color = trait, width = 0.5)),
                colorbar = list(ticksuffix = pct(l), len = 0.6, thickness = 12))
        ),
        mise_en_page(sombre(), dragmode = FALSE, margin = list(l = 0, r = 0, t = 0, b = 0),
          geo = list(visible = FALSE, fitbounds = "locations", bgcolor = "rgba(0,0,0,0)",
                     projection = list(type = "natural earth")))
      )
    }) |> shiny::bindCache(input$indicateur, input$milieu, input$annee, lang(), sombre())

    # The countries where access is lowest, as a list of buttons.
    output$t_retard <- shiny::renderText(tr("behind", lang()))
    output$retard <- shiny::renderUI({
      d <- acces_le_plus_faible(valeurs(), input$indicateur); l <- lang()
      if (!nrow(d)) return(NULL)
      htmltools::HTML(paste0("<ol>", paste0(sprintf(
        '<li><button type="button" class="lien-pays" data-input="%s" data-valeur="%s">%s</button><span class="num">%s</span></li>',
        session$ns("liste_click"), d$code, htmltools::htmlEscape(d$area), fmt_pc(d$valeur, l)), collapse = ""), "</ol>"))
    })

    # The country clicked, on the map or in the list, for the parent to open
    # its profile.
    choisi <- shiny::reactiveVal()
    shiny::observeEvent(input$carte_click, choisi(input$carte_click))
    shiny::observeEvent(input$liste_click, choisi(input$liste_click))
    shiny::reactive(choisi())
  })
}
