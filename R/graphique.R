# graphique.R
# A custom Shiny output for plotly.js charts (see www/graphique.js), and the
# small helpers that build figures as plain R lists.
#
#   graphique_output("id")            UI: the container
#   output$id <- render_graphique(..)  server: returns list(data, layout)
#   input$id_click                     the customdata of the clicked point

graphique_output <- function(id, height = "100%", min_height = "300px") {
  # "../": under shinylive the app runs in shiny-eau/app_<id>/, and these
  # files are published next to it, in shiny-eau/, as plain static files:
  # downloaded compressed and cached by the browser, never served by R.
  # Locally (runApp) "../" resolves to the root, where www/ is served.
  htmltools::tagList(
    htmltools::htmlDependency("plotly", "2.25.2", src = c(href = ".."), script = "plotly.min.js",
                              all_files = FALSE),
    htmltools::htmlDependency("graphique", "1.1", src = c(href = ".."), script = "graphique.js",
                              all_files = FALSE),
    htmltools::div(id = id, class = "graphique-output",
                   style = sprintf("width:100%%;height:%s;min-height:%s;", height, min_height))
  )
}

render_graphique <- function(expr, env = parent.frame(), quoted = FALSE) {
  func <- shiny::installExprFunction(expr, "func", env, quoted, label = "render_graphique")
  shiny::createRenderFunction(func, function(value, session, name, ...) {
    if (is.null(value)) return(NULL)
    # Plain JSON, NA as null (plotly leaves a gap).
    jsonlite::toJSON(value, auto_unbox = TRUE, null = "null", na = "null", digits = NA)
  }, outputFunc = graphique_output)
}

# One trace. Vectors stay arrays even with one element (I() keeps them so).
trace <- function(...) {
  t <- list(...)
  for (k in c("x", "y", "z", "locations", "customdata", "text")) if (!is.null(t[[k]])) t[[k]] <- I(t[[k]])
  t
}

# Layout shared by every chart: transparent background, text colour and grid
# that follow the light or dark mode. Extra arguments are merged in.
mise_en_page <- function(sombre = FALSE, ...) {
  texte <- if (isTRUE(sombre)) "#e2e8f0" else "#1e293b"
  grille <- if (isTRUE(sombre)) "#2F3D55" else "#E5EAF0"
  # The fonts of the interface (theme.R); a family name with a digit must be quoted.
  police <- "'Source Sans 3', 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"
  base <- list(
    paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
    font = list(family = police, color = texte, size = 13),
    xaxis = list(gridcolor = grille, zeroline = FALSE, fixedrange = TRUE),
    yaxis = list(gridcolor = grille, zeroline = FALSE, fixedrange = TRUE),
    legend = list(orientation = "h", y = -0.18),
    margin = list(l = 48, r = 16, t = 16, b = 48),
    hoverlabel = list(font = list(family = police))
  )
  modifyList(base, list(...))
}

figure <- function(data, layout, config = list()) {
  list(data = data, layout = layout,
       config = modifyList(list(modeBarButtonsToRemove = I(c("lasso2d", "select2d", "autoScale2d"))), config))
}

pct <- function(lang) if (lang == "fr") " %" else "%"
