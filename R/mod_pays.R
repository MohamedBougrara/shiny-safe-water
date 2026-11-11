# mod_pays.R
# Country profile: headline figures, the service ladder over time, the gap
# between cities and countryside, the three tests of safe water, and a
# comparison with up to three other countries.
# Returns a function the parent calls to select a country (map click), and
# the country shown.

pays_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 300,
      shiny::selectizeInput(ns("pays"), "Country", choices = choix_pays(), selected = "SEN"),
      shiny::selectizeInput(ns("comparer"), "Compare with (up to 3)", choices = choix_pays(),
                            selected = c("MAR", "IND"), multiple = TRUE,
                            options = list(maxItems = 3, plugins = list("remove_button")))
    ),
    # One sentence that reads the country: rewritten for each selection.
    shiny::p(class = "lecture", shiny::textOutput(ns("lecture"), inline = TRUE)),
    bslib::layout_column_wrap(
      width = 1 / 3, fill = FALSE,
      bslib::value_box(shiny::textOutput(ns("t_derniere")), shiny::textOutput(ns("v_derniere")),
                       shiny::textOutput(ns("s_derniere")), showcase = icone("droplet-fill"),
                       theme = "primary"),
      bslib::value_box(shiny::textOutput(ns("t_evol")), shiny::textOutput(ns("v_evol")),
                       shiny::textOutput(ns("s_evol")), showcase = icone("graph-up-arrow")),
      bslib::value_box(shiny::textOutput(ns("t_sans")), shiny::textOutput(ns("v_sans")),
                       showcase = icone("people-fill"), theme = "danger")
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(full_screen = TRUE, min_height = 340,
        bslib::card_header(shiny::textOutput(ns("t_echelle"), inline = TRUE)),
        graphique_output(ns("echelle"))),
      bslib::card(full_screen = TRUE, min_height = 340,
        bslib::card_header(shiny::textOutput(ns("t_criteres"), inline = TRUE)),
        graphique_output(ns("criteres")))
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(full_screen = TRUE, min_height = 320,
        bslib::card_header(shiny::textOutput(ns("t_ecart"), inline = TRUE)),
        graphique_output(ns("ecart"))),
      bslib::card(full_screen = TRUE, min_height = 320,
        bslib::card_header(shiny::textOutput(ns("t_comparer"), inline = TRUE)),
        graphique_output(ns("comparaison")))
    )
  )
}

# annee: the year shared with the map and the ranking, marked on the charts.
pays_server <- function(id, lang, sombre, annee = shiny::reactiveVal()) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observeEvent(lang(), {
      shiny::updateSelectizeInput(session, "pays", label = tr("country", lang()))
      shiny::updateSelectizeInput(session, "comparer", label = tr("compare_with", lang()))
    })
    titres <- c(t_echelle = "ladder_title", t_criteres = "tests_title",
                t_ecart = "gap_title", t_comparer = "compare_title",
                t_derniere = "latest", t_evol = "since_2015", t_sans = "people_without")
    lapply(names(titres), function(sortie) {
      output[[sortie]] <- shiny::renderText(tr(titres[[sortie]], lang()))
    })

    code <- shiny::reactive({
      shiny::req(input$pays %in% PAYS$code)
      input$pays
    })
    donnees  <- shiny::reactive(serie(D$eau, code())) |> shiny::bindCache(code())
    chiffres <- shiny::reactive(derniere(D$eau, code()))

    output$v_derniere <- shiny::renderText(fmt_pc(chiffres()$valeur, lang()))
    output$s_derniere <- shiny::renderText({
      if (is.na(chiffres()$annee)) tr("no_estimate", lang())
      else paste(tr("ind_safely", lang()), "·", chiffres()$annee)
    })
    output$v_evol <- shiny::renderText({
      e <- chiffres()$evolution
      if (is.na(e)) "-" else paste0(if (e >= 0) "+" else "", formatC(e, format = "f", digits = 1,
                                    decimal.mark = if (lang() == "fr") "," else "."), " ", tr("points", lang()))
    })
    output$s_evol <- shiny::renderText({
      if (is.na(chiffres()$depuis)) "" else paste(chiffres()$depuis, "→", chiffres()$annee)
    })
    output$v_sans <- shiny::renderText({
      d <- donnees(); d <- d[d$residence == "Total" & !is.na(d$without_safe), ]
      if (!nrow(d)) return("-")
      fmt_nb(round(d$without_safe[which.max(d$year)]), lang())
    })

    output$lecture <- shiny::renderText(lecture_pays(code(), chiffres(), projection(D$eau, code()), lang()))

    axe_pc <- function(l) list(range = c(0, 100), ticksuffix = pct(l), fixedrange = TRUE)
    # The year chosen on the map or in the ranking, as a dotted line.
    repere <- function() {
      a <- annee()
      if (is.null(a)) return(list())
      list(list(type = "line", x0 = a, x1 = a, yref = "paper", y0 = 0, y1 = 1,
                line = list(dash = "dot", width = 1.5, color = if (isTRUE(sombre())) "#94a3b8" else "#5C6A80")))
    }

    # Service ladder: stacked areas, safest at the bottom.
    output$echelle <- render_graphique({
      d <- donnees(); d <- d[d$residence == "Total", ]; l <- lang()
      shiny::validate(shiny::need(nrow(d) > 0, tr("no_estimate", l)))
      sans_sm <- all(is.na(d$safely))
      niveaux <- if (sans_sm) c("basic_plus", "limited", "unimproved", "surface")
                 else c("safely", "basic", "limited", "unimproved", "surface")
      traces <- lapply(niveaux, function(n) {
        lib <- if (n == "basic_plus") tr("ind_basic_plus", l) else tr(paste0("lvl_", n), l)
        coul <- COULEURS_ECHELLE[[if (n == "basic_plus") "basic" else n]]
        trace(type = "scatter", mode = "lines", x = d$year, y = round(d[[n]], 1), stackgroup = "un",
              name = lib, line = list(width = 0.5, color = coul), fillcolor = coul,
              hovertemplate = paste0(lib, " : %{y}", pct(l), "<extra></extra>"))
      })
      lay <- mise_en_page(sombre(), yaxis = axe_pc(l), hovermode = "x unified", shapes = repere())
      if (sans_sm) lay$annotations <- list(list(text = tr("no_safely", l), x = 0, y = 1.1, xref = "paper",
        yref = "paper", showarrow = FALSE, xanchor = "left", font = list(size = 11)))
      figure(traces, lay)
    }) |> shiny::bindCache(code(), lang(), sombre(), annee())

    # The three tests of safely managed water, latest year with an estimate.
    output$criteres <- render_graphique({
      l <- lang()
      c3 <- D$criteres[D$criteres$code == code(), ]
      c3 <- c3[stats::complete.cases(c3[, c("available", "premises", "uncontaminated")]), ]
      shiny::validate(shiny::need(nrow(c3) > 0, tr("no_safely", l)))
      c3 <- c3[which.max(c3$year), ]
      v <- unname(unlist(c3[, c("uncontaminated", "premises", "available")]))
      libs <- vapply(c("crit_uncontaminated", "crit_premises", "crit_available"), tr, "", l, USE.NAMES = FALSE)
      figure(
        list(trace(type = "bar", orientation = "h", x = round(v, 1), y = libs,
                   marker = list(color = c("#1f4e89", "#295489", "#7DA4D4")),
                   text = fmt_pc(v, l), textposition = "outside", cliponaxis = FALSE, hoverinfo = "none")),
        mise_en_page(sombre(), showlegend = FALSE, margin = list(l = 150, r = 24, t = 8, b = 36),
          xaxis = list(range = c(0, 118), showticklabels = FALSE, showgrid = FALSE, fixedrange = TRUE),
          yaxis = list(showgrid = FALSE, fixedrange = TRUE, automargin = TRUE),
          annotations = list(list(text = as.character(c3$year), x = 1, y = -0.1, xref = "paper",
            yref = "paper", showarrow = FALSE, xanchor = "right", font = list(size = 11))))
      )
    }) |> shiny::bindCache(code(), lang(), sombre())

    # Cities and countryside.
    output$ecart <- render_graphique({
      d <- donnees(); l <- lang()
      d <- d[d$residence %in% c("Urban", "Rural") & !is.na(d$safely), ]
      shiny::validate(shiny::need(nrow(d) > 0, tr("no_safely", l)))
      traces <- lapply(c("Urban", "Rural"), function(m) {
        s <- d[d$residence == m, ]
        trace(type = "scatter", mode = "lines+markers", x = s$year, y = round(s$safely, 1),
              name = tr(paste0("res_", m), l), marker = list(size = 5),
              line = list(color = if (m == "Urban") "#295489" else "#e07a5f", width = 2.5))
      })
      figure(traces, mise_en_page(sombre(), yaxis = axe_pc(l), hovermode = "x unified", shapes = repere()))
    }) |> shiny::bindCache(code(), lang(), sombre(), annee())

    # Comparison: debounced, so that picking several countries redraws once.
    a_comparer <- shiny::reactive(unique(c(code(), input$comparer))) |> shiny::debounce(400)
    output$comparaison <- render_graphique({
      l <- lang(); codes <- a_comparer()
      d <- D$eau[D$eau$code %in% codes & D$eau$residence == "Total" & !is.na(D$eau$safely), ]
      shiny::validate(shiny::need(nrow(d) > 0, tr("no_safely", l)))
      palette <- c("#295489", "#e07a5f", "#2f7d5b", "#8e6bbf")
      traces <- Filter(Negate(is.null), lapply(seq_along(codes), function(i) {
        s <- d[d$code == codes[i], ]
        if (!nrow(s)) return(NULL)
        trace(type = "scatter", mode = "lines", x = s$year, y = round(s$safely, 1),
              name = PAYS$area[PAYS$code == codes[i]],
              line = list(color = palette[i], width = if (i == 1) 3.5 else 2))
      }))
      figure(traces, mise_en_page(sombre(), yaxis = axe_pc(l), hovermode = "x unified", shapes = repere()))
    })

    # Called by the parent when a country is clicked on the map.
    list(
      selectionner = function(code) {
        if (!is.null(code) && code %in% PAYS$code) shiny::updateSelectizeInput(session, "pays", selected = code)
      },
      # The country shown, for the address of the page.
      code = code
    )
  })
}
