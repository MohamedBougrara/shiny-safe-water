# mod_regions.R
# Regions and income groups since 2000, the 2030 goal, and the year each one
# would reach universal access at its 2015-2024 pace.

regions_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 300,
      shiny::radioButtons(ns("groupe"), "Group by",
                          choices = c("SDG region" = "SDG region", "Income group" = "Income group")),
      shiny::p(class = "note", shiny::textOutput(ns("note"), inline = TRUE))
    ),
    bslib::card(full_screen = TRUE, min_height = 440,
      bslib::card_header(shiny::textOutput(ns("titre"), inline = TRUE)),
      graphique_output(ns("courbes"), min_height = "380px")),
    bslib::card(
      bslib::card_header(shiny::textOutput(ns("t_rythme"), inline = TRUE)),
      shiny::uiOutput(ns("rythmes")))
  )
}

regions_server <- function(id, lang, sombre) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observeEvent(lang(), {
      l <- lang()
      shiny::updateRadioButtons(session, "groupe", label = tr("group_by", l),
        choices = stats::setNames(c("SDG region", "Income group"), c(tr("grp_sdg", l), tr("grp_income", l))),
        selected = input$groupe)
    })
    output$titre    <- shiny::renderText(tr("regions_title", lang()))
    output$note     <- shiny::renderText(tr("projection_note", lang()))
    output$t_rythme <- shiny::renderText(paste(tr("pace", lang()), "·", tr("reach", lang())))

    donnees <- shiny::reactive({
      shiny::req(input$groupe)
      regions(D$eau, input$groupe)
    }) |> shiny::bindCache(input$groupe)

    zones <- shiny::reactive({
      d <- donnees()
      unique(d[order(d$order), c("code", "area")])
    })

    output$courbes <- render_graphique({
      d <- donnees(); z <- zones(); l <- lang()
      palette <- c("#1e293b", "#295489", "#7DA4D4", "#2f7d5b", "#e9c46a", "#e07a5f", "#b23a48", "#8e6bbf", "#5C6A80")
      traces <- lapply(seq_len(nrow(z)), function(i) {
        s <- d[d$code == z$code[i] & !is.na(d$safely), ]
        s <- s[order(s$year), ]
        monde <- z$code[i] == "WLD"
        trace(type = "scatter", mode = "lines", x = s$year, y = round(s$safely, 1),
              name = nom_groupe(z$area[i], l),
              line = list(color = if (monde && isTRUE(sombre())) "#e2e8f0" else palette[i],
                          width = if (monde) 4 else 2))
      })
      figure(traces, mise_en_page(sombre(),
        yaxis = list(range = c(0, 100), ticksuffix = pct(l), fixedrange = TRUE),
        xaxis = list(range = c(2000, 2031), fixedrange = TRUE), hovermode = "x unified",
        legend = list(orientation = "v", x = 1.02, y = 1),
        shapes = list(list(type = "line", x0 = 2000, x1 = 2030, y0 = 99, y1 = 99,
                           line = list(dash = "dot", color = "#2f7d5b", width = 2))),
        annotations = list(list(x = 2030, y = 99, text = tr("goal", l), showarrow = FALSE,
                                xanchor = "right", yanchor = "bottom", font = list(size = 12, color = "#2f7d5b")))))
    }) |> shiny::bindCache(input$groupe, lang(), sombre())

    output$rythmes <- shiny::renderUI({
      d <- donnees(); z <- zones(); l <- lang()
      t <- do.call(rbind, lapply(seq_len(nrow(z)), function(i) {
        pr <- projection(D$eau, z$code[i])
        s24 <- d$safely[d$code == z$code[i] & d$year == 2024]
        data.frame(zone = nom_groupe(z$area[i], l), s2024 = if (length(s24)) s24 else NA,
                   rythme = pr$rythme, etat = pr$etat, annee = pr$annee)
      }))
      t <- t[order(-t$s2024), ]
      tableau_html(t, legende = tr("reach", l), colonnes = list(
        zone = list(titre = ""),
        s2024 = list(titre = "2024", num = TRUE, cellule = function(v, d) fmt_pc(v, l)),
        rythme = list(titre = paste0(tr("pace", l), " (", tr("pts_year", l), ")"), num = TRUE,
          cellule = function(v, d) ifelse(is.na(v), "-", formatC(v, format = "f", digits = 2,
                                                                  decimal.mark = if (l == "fr") "," else "."))),
        annee = list(titre = tr("reach", l), num = TRUE, cellule = function(v, d)
          ifelse(d$etat == "atteint", tr("already", l), ifelse(d$etat == "jamais", tr("never", l),
                 ifelse(d$etat == "inconnu", "-", paste0("<strong>", v, "</strong>")))))))
    })
  })
}
