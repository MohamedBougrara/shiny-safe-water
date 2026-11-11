# ui.R
# The page: a navbar with one tab per module. Called when the app runs
# locally, and by publier.R, which renders it once for the published app.

interface <- function() {
  bslib::page_navbar(
    id = "onglets",
    title = shiny::textOutput("titre_app", inline = TRUE),
    window_title = "Safe drinking water, country by country \u00b7 Mohamed Bougrara",
    theme = theme_app(),
    fillable = c("carte"),
    header = htmltools::tagList(
      dependances_statiques(),
      htmltools::tags$head(htmltools::tags$meta(name = "author", content = "Mohamed Bougrara"))
    ),
    bslib::nav_panel(shiny::textOutput("nav_carte", inline = TRUE), value = "carte",
                     icon = icone("globe-americas"), carte_ui("carte")),
    bslib::nav_panel(shiny::textOutput("nav_pays", inline = TRUE), value = "pays",
                     icon = icone("flag"), pays_ui("pays")),
    bslib::nav_panel(shiny::textOutput("nav_regions", inline = TRUE), value = "regions",
                     icon = icone("graph-up"), regions_ui("regions")),
    bslib::nav_panel(shiny::textOutput("nav_classement", inline = TRUE), value = "classement",
                     icon = icone("list-ol"), classement_ui("classement")),
    bslib::nav_panel(shiny::textOutput("nav_apropos", inline = TRUE), value = "apropos",
                     icon = icone("info-circle"), shiny::uiOutput("apropos")),
    bslib::nav_spacer(),
    bslib::nav_item(shiny::radioButtons("langue", NULL, choices = c("EN" = "en", "FR" = "fr"), inline = TRUE)),
    bslib::nav_item(bslib::input_dark_mode(id = "mode", mode = "light"))
  )
}
