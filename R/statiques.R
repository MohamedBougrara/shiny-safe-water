# statiques.R
# The CSS and JavaScript of the page, published as static files next to the
# app ("../", as plotly.js: see R/graphique.R). Under shinylive, R would serve
# each of them itself, one after the other, and compile some with Sass first;
# static files are downloaded by the browser while R starts, compressed and
# cached. publier.R writes them:
#   theme/<dependency>/  compiled with the theme of the app (R/theme.R);
#   lib/<dependency>/    copied from the webR library, so that they match
#                        exactly the R packages webR runs.
# Each folder replaces the dependency of the same name: htmltools keeps, for
# each name, the highest version.

# Bootstrap, the bslib components, and the CSS of Shiny, selectize and the
# slider, that Shiny would otherwise compile for the current theme.
FICHIERS_THEME <- list(
  bootstrap = c("bootstrap.min.css", "bootstrap.bundle.min.js"),
  "bslib-component-css" = "bslib-component-css.min.css",
  "shiny-css" = "shiny-sass.css",
  selectize = c("selectize.css", "selectize.min.js", "selectize-plugin-a11y.min.js"),
  "ionrangeslider-css" = "ionRangeSlider.css"
)

# The other files of the page, by their path in the R library.
FICHIERS_WEBR <- list(
  jquery = "shiny/www/shared/jquery.min.js",
  "shiny-busy-indicators" = "shiny/www/shared/busy-indicators/busy-indicators.css",
  "shiny-javascript" = "shiny/www/shared/shiny.min.js",
  bs3compat = c("bslib/bs3compat/js/transition.js", "bslib/bs3compat/js/tabs.js",
                "bslib/bs3compat/js/bs3compat.js"),
  "htmltools-fill" = "htmltools/fill/fill.css",
  "bslib-component-js" = c("bslib/components/dist/components.min.js",
                           "bslib/components/dist/web-components.min.js"),
  "bslib-tag-require" = "bslib/components/tag-require.js",
  "ionrangeslider-javascript" = "shiny/www/shared/ionrangeslider/js/ion.rangeSlider.min.js",
  strftime = "shiny/www/shared/strftime/strftime-min.js"
)
MODULES_JS <- "web-components.min.js"  # loaded as ES modules

dependance_statique <- function(nom, dossier, fichiers) {
  f <- basename(fichiers)
  js <- lapply(f[endsWith(f, ".js")], function(s) c(list(src = s), if (s %in% MODULES_JS) list(type = "module")))
  htmltools::htmlDependency(
    nom, "999", src = c(href = paste0("../", dossier, "/", nom)),
    stylesheet = f[endsWith(f, ".css")], script = js,
    meta = if (nom == "bootstrap") list(viewport = "width=device-width, initial-scale=1, shrink-to-fit=no"),
    all_files = FALSE)
}

dependances_statiques <- function() {
  htmltools::tagList(
    # Placed after the navbar (rendered with the Bootstrap 5 theme): from here
    # on Shiny sees no bslib theme, so its inputs take their static CSS,
    # replaced below by the compiled files, instead of compiling it.
    htmltools::tagFunction(function() {
      shiny::shinyOptions(bootstrapTheme = NULL)
      NULL
    }),
    lapply(names(FICHIERS_THEME), function(n) dependance_statique(n, "theme", FICHIERS_THEME[[n]])),
    # In webR only (and when publier.R renders the published page): run
    # locally, R serves the files of its own packages.
    if (identical(R.version$os, "emscripten") || nzchar(Sys.getenv("EAU_PAGE_PUBLIEE"))) {
      lapply(names(FICHIERS_WEBR), function(n) dependance_statique(n, "lib", FICHIERS_WEBR[[n]]))
    }
  )
}
