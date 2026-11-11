# app.R
# Safe drinking water, country by country: an R Shiny app on the WHO/UNICEF
# JMP estimates (2000-2024). Mohamed Bougrara.
#
# Structure:
#   R/donnees.R        data loaded once, pure functions (tested)
#   R/i18n.R           English and French strings, number formats
#   R/ui.R             the page (navbar, tabs)
#   R/theme.R          bslib theme (light and dark), compiled by publier.R
#   R/statiques.R      CSS and JavaScript published as static files
#   R/graphique.R      custom Shiny output for plotly.js (www/graphique.js)
#   R/tableau.R        HTML tables built with htmltools
#   R/mod_carte.R      world map module        -> returns the clicked country
#   R/mod_pays.R       country profile module  -> exposes selectionner()
#   R/mod_regions.R    regions and 2030 module
#   R/mod_classement.R ranking module, CSV export
# Shiny sources every file of R/ before running this one.
#
# Run locally, from this folder: shiny::runApp()
# Published as a static site with shinylive (webR): see publier.R.

library(shiny)

# Explicit app-wide cache for bindCache(): shared by all sessions, bounded in
# memory. Under webR (shinylive) Shiny has no default cache object.
shinyOptions(cache = cachem::cache_mem(max_size = 64 * 1024^2))

# The page. Published (publier.R), it is already rendered: data/page.html is
# served as it is, so the browser's R neither loads bslib (4 s under webR, for
# its Sass compiler) nor builds and renders the interface (2.5 s more).
# Run locally, there is no such file and the page is built as usual (R/ui.R).
page_prete <- file.path("data", "page.html")
ui <- if (file.exists(page_prete)) {
  html <- paste(readLines(page_prete, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  # A UI function may answer the request itself: Shiny then sends this as it is.
  function(req) {
    structure(list(status = 200L, content_type = "text/html; charset=UTF-8", content = html,
                   headers = list()), class = "httpResponse")
  }
} else {
  interface()
}

# Tabs, and their names in the address of the page (?tab=country&country=SEN).
ONGLETS <- c(map = "carte", country = "pays", regions = "regions", ranking = "classement", about = "apropos")

server <- function(input, output, session) {

  # Language: ?lang=fr in the address opens the app in French (read by
  # www/graphique.js, which also sees the address of the shinylive page).
  # One source of truth for the language, fed by the address or by a click.
  langue <- reactiveVal("en")
  observeEvent(input$lang_url, once = TRUE, {
    if (input$lang_url %in% c("en", "fr")) {
      langue(input$lang_url)
      updateRadioButtons(session, "langue", selected = input$lang_url)
    }
  })
  observeEvent(input$langue, ignoreInit = TRUE, {
    if (input$langue %in% c("en", "fr")) langue(input$langue)
  })
  lang <- reactive(langue())
  sombre <- reactive(identical(input$mode, "dark"))

  output$titre_app      <- renderText(tr("app_title", lang()))
  output$nav_carte      <- renderText(tr("nav_map", lang()))
  output$nav_pays       <- renderText(tr("nav_country", lang()))
  output$nav_regions    <- renderText(tr("nav_regions", lang()))
  output$nav_classement <- renderText(tr("nav_table", lang()))
  output$nav_apropos    <- renderText(tr("nav_about", lang()))

  # One year for the whole app: the map, the ranking and the marker on the
  # charts of the country profile follow each other.
  annee <- reactiveVal(ANNEES[2])
  clic <- carte_server("carte", lang, sombre, annee)
  pays <- pays_server("pays", lang, sombre, annee)
  regions_server("regions", lang, sombre)
  choisi <- classement_server("classement", lang, sombre, annee)

  # Modules talking to each other: a click on the map, or on a country of
  # the ranking, opens that country's profile.
  ouvrir_pays <- function(code) {
    pays$selectionner(code)
    updateNavbarPage(session, "onglets", selected = "pays")
  }
  observeEvent(clic(), ouvrir_pays(clic()))
  observeEvent(choisi(), ouvrir_pays(choisi()))

  # A link that can be shared: the address of the page names the tab and the
  # country (written by www/graphique.js), and opens the app on them.
  observeEvent(input$adresse, once = TRUE, {
    a <- input$adresse
    if (!is.null(a$pays)) pays$selectionner(a$pays)
    if (isTRUE(a$onglet %in% names(ONGLETS))) {
      updateNavbarPage(session, "onglets", selected = ONGLETS[[a$onglet]])
    }
  })
  observe({
    onglet <- names(ONGLETS)[match(input$onglets, ONGLETS)]
    req(!is.na(onglet))
    session$sendCustomMessage("adresse", list(
      lang = lang(), tab = onglet, country = if (onglet == "country") pays$code()))
  })

  output$apropos <- renderUI({
    l <- lang()
    div(class = "container about", style = "max-width: 760px; padding: 24px 8px;",
      h2(tr("about_title", l)),
      p(tr("about_data", l)),
      p(tr("about_build", l)),
      h3(tr("about_skills", l), style = "font-size: 1.15rem; margin-top: 1.5rem;"),
      tags$ul(lapply(tr("skills", l), tags$li)))
  })
}

shinyApp(ui, server)
