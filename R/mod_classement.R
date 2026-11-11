# mod_classement.R
# Ranking of countries for one year, filtered by continent and income group,
# searchable and sortable (list or column headers), with a CSV export of
# exactly what is shown. Returns the country the user clicks in the table.

TRIS <- c("safely", "basic_plus", "surface", "evolution", "population", "area")
# Label key of each sort option.
LIB_TRIS <- c(safely = "col_safely", basic_plus = "col_basic_plus", surface = "col_surface",
              evolution = "col_change", population = "col_population", area = "col_area")

classement_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 300,
      shiny::sliderInput(ns("annee"), "Year", min = ANNEES[1], max = ANNEES[2], value = ANNEES[2],
                         step = 1, sep = "", ticks = FALSE),
      shiny::selectizeInput(ns("continent"), "Continent", choices = CONTINENTS, multiple = TRUE,
                            options = list(plugins = list("remove_button"), placeholder = "All")),
      shiny::selectizeInput(ns("revenu"), "Income group", choices = REVENUS, multiple = TRUE,
                            options = list(plugins = list("remove_button"), placeholder = "All")),
      shiny::textInput(ns("cherche"), "Search a country"),
      shiny::selectInput(ns("tri"), "Sort by", choices = stats::setNames(TRIS, TRIS)),
      # Inline icon rather than Font Awesome: one stylesheet and one font less.
      shiny::downloadButton(ns("csv"), htmltools::tagList(icone("download"), " Download CSV"),
                            class = "btn-primary w-100", icon = NULL)
    ),
    bslib::card(full_screen = TRUE,
      bslib::card_header(shiny::textOutput(ns("titre"), inline = TRUE)),
      shiny::p(class = "note aide-tableau", shiny::textOutput(ns("aide"), inline = TRUE)),
      shiny::uiOutput(ns("tableau")))
  )
}

# annee: the year shared by the map, the ranking and the country profile.
classement_server <- function(id, lang, sombre, annee = shiny::reactiveVal()) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observeEvent(input$annee, annee(input$annee))
    shiny::observeEvent(annee(), {
      if (!identical(annee(), input$annee)) shiny::updateSliderInput(session, "annee", value = annee())
    })

    shiny::observeEvent(lang(), {
      l <- lang()
      shiny::updateSliderInput(session, "annee", label = tr("year", l))
      shiny::updateSelectizeInput(session, "continent", label = tr("filter_continent", l),
        choices = stats::setNames(CONTINENTS, nom_groupe(CONTINENTS, l)), selected = input$continent,
        options = list(plugins = list("remove_button"), placeholder = tr("all", l)))
      shiny::updateSelectizeInput(session, "revenu", label = tr("filter_income", l),
        choices = stats::setNames(REVENUS, nom_groupe(REVENUS, l)), selected = input$revenu,
        options = list(plugins = list("remove_button"), placeholder = tr("all", l)))
      shiny::updateTextInput(session, "cherche", label = tr("search", l))
      shiny::updateSelectInput(session, "tri", label = tr("sort_by", l),
        choices = stats::setNames(TRIS, vapply(LIB_TRIS[TRIS], tr, "", l)), selected = input$tri)
      session$sendCustomMessage("libelle", list(id = session$ns("csv"), texte = tr("download", l)))
    })

    # Typing in the search box filters after a short pause, not at each key.
    cherche <- shiny::reactive(trimws(input$cherche %||% "")) |> shiny::debounce(300)

    tri <- shiny::reactive(if (is.null(input$tri) || !input$tri %in% TRIS) "safely" else input$tri)

    donnees <- shiny::reactive({
      shiny::req(input$annee)
      d <- classement(D$eau, input$annee, input$continent, input$revenu)
      if (nzchar(cherche())) d <- d[grepl(cherche(), d$area, ignore.case = TRUE, fixed = FALSE) |
                                    toupper(cherche()) == d$code, ]
      ordre <- if (tri() == "area") order(d$area) else order(-d[[tri()]], d$area, na.last = TRUE)
      d[ordre, ]
    })

    output$titre <- shiny::renderText({
      paste0(tr("nav_table", lang()), " · ", input$annee, " · ", nrow(donnees()), " ", tr("countries", lang()))
    })

    output$aide <- shiny::renderText(tr("table_hint", lang()))

    output$tableau <- shiny::renderUI({
      d <- donnees(); l <- lang()
      shiny::validate(shiny::need(nrow(d) > 0, tr("no_match", l)))
      # A country opens its profile; a column header sorts on that column.
      tableau_html(d, legende = tr("nav_table", l),
        tri = list(input = session$ns("tri_clic"), actif = tri()),
        colonnes = list(
        area = list(titre = tr("col_country", l), tri = "area", cellule = function(v, d)
          sprintf('<button type="button" class="lien-pays" data-input="%s" data-valeur="%s">%s</button>',
                  session$ns("clic"), d$code, htmltools::htmlEscape(v))),
        continent = list(titre = tr("col_continent", l), cellule = function(v, d) nom_groupe(v, l)),
        income = list(titre = tr("col_income", l), cellule = function(v, d) ifelse(is.na(v), "-", nom_groupe(v, l))),
        safely = list(titre = tr("col_safely", l), tri = "safely", cellule = cellule_barre("#295489", l)),
        basic_plus = list(titre = tr("col_basic_plus", l), tri = "basic_plus", cellule = cellule_barre("#7DA4D4", l)),
        surface = list(titre = tr("col_surface", l), tri = "surface", cellule = cellule_barre("#b23a48", l)),
        evolution = list(titre = tr("col_change", l), tri = "evolution", num = TRUE,
                         cellule = function(v, d) fmt_pts(v, l)),
        population = list(titre = tr("col_population", l), tri = "population", num = TRUE,
                          cellule = function(v, d) fmt_nb(round(v), l))))
    })

    # A click on a column header: the "Sort by" list follows.
    shiny::observeEvent(input$tri_clic, {
      if (input$tri_clic %in% TRIS) shiny::updateSelectInput(session, "tri", selected = input$tri_clic)
    })

    # Exactly the rows on screen, with English column names for reuse.
    output$csv <- shiny::downloadHandler(
      filename = function() paste0("safe-water-", input$annee, ".csv"),
      content = function(fichier) {
        d <- donnees()[, c("code", "area", "continent", "income", "safely", "basic_plus", "surface",
                           "evolution", "population")]
        names(d) <- c("iso3", "country", "continent", "income_group", "safely_managed_pct",
                      "at_least_basic_pct", "surface_water_pct", "change_since_2015_pts", "population")
        utils::write.csv(d, fichier, row.names = FALSE, na = "")
      }
    )

    # The country clicked in the table, for the parent to open its profile.
    shiny::reactive(input$clic)
  })
}
