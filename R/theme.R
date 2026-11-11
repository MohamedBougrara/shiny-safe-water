# theme.R
# The bslib theme in the portfolio's colours (light and dark), and the colours
# of the charts.
#
# Compiling a bslib theme runs Sass: about 1.5 s natively, several seconds in
# webR, at every visit. So the theme is compiled once, by publier.R, into
# static files (www/theme/), and the app starts on bslib's default theme,
# shipped already compiled, whose CSS is swapped for the static files
# (R/statiques.R).

# The theme itself: compiled by publier.R, not at start-up.
theme_source <- function() {
  bslib::bs_theme(
    version = 5,
    bg = "#f8fafc", fg = "#1e293b",
    primary = "#295489", secondary = "#5C6A80",
    success = "#2f7d5b", danger = "#b23a48",
    base_font = bslib::font_collection("Source Sans 3", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"),
    heading_font = bslib::font_collection("Source Sans 3", "Segoe UI", "Roboto", "Arial", "sans-serif"),
    "border-radius" = "0.5rem",
    "card-border-color" = "#D7DEE7"
  ) |>
    bslib::bs_add_rules("
      .navbar-brand { font-weight: 700; }
      .bslib-value-box .value-box-value { font-weight: 800; letter-spacing: -0.01em; }
      .note { color: var(--bs-secondary-color); font-size: .9rem; }
      .card-header { font-weight: 650; }
      [data-bs-theme='dark'] { --bs-body-bg: #0b1120; --bs-body-color: #e2e8f0; }
      [data-bs-theme='dark'] .card { --bs-card-bg: #151e32; --bs-card-border-color: #2F3D55; }
      [data-bs-theme='dark'] .bslib-value-box { --bslib-value-box-bg: #151e32; }
      .about li { margin-bottom: .35rem; }
      .graphique-message { color: var(--bs-secondary-color); padding: 1rem; }
      .tableau-defile { max-height: 640px; overflow: auto; }
      .tableau-defile thead th { position: sticky; top: 0; background: var(--bs-body-bg); z-index: 1; }
      .barre { display: flex; align-items: center; gap: 6px; white-space: nowrap; }
      .barre i { flex: none; height: 10px; border-radius: 2px; }
      .num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
      /* Buttons inside tables: a country opens its profile, a header sorts. */
      .lien-pays, .tri-col { padding: 0; border: 0; background: none; font: inherit; color: inherit; text-align: inherit; }
      .lien-pays { color: var(--bs-link-color); text-decoration: underline; text-decoration-color: transparent;
                   text-underline-offset: 3px; }
      .lien-pays:hover, .lien-pays:focus-visible { text-decoration-color: currentColor; }
      .tri-col { font-weight: inherit; cursor: pointer; text-decoration: underline dotted;
                 text-decoration-color: var(--bs-secondary-color); text-underline-offset: 4px; }
      .tri-col:hover, .tri-col:focus-visible { text-decoration-style: solid; text-decoration-color: currentColor; }
      th[aria-sort] .tri-col { text-decoration: none; }
      th[aria-sort='descending'] .tri-col::after { content: '\\00a0\\2193'; }
      th[aria-sort='ascending'] .tri-col::after { content: '\\00a0\\2191'; }
      .aide-tableau { margin: 0; padding: .5rem 1rem 0; }
      .lecture { margin: 0 0 1rem; font-size: 1.15rem; line-height: 1.5; max-width: 60rem; }
      .retard { margin-top: .5rem; padding-top: 1rem; border-top: 1px solid var(--bs-border-color); }
      .retard-titre { margin: 0 0 .25rem; font-size: 1rem; font-weight: 650; }
      .retard ol { margin: 0; padding: 0; list-style: none; counter-reset: rang; }
      .retard li { display: flex; align-items: baseline; gap: .5rem; padding: .3rem 0; counter-increment: rang; }
      .retard li::before { content: counter(rang); min-width: 1ch; color: var(--bs-secondary-color); }
      .retard li .num { margin-left: auto; }
      .tableau-defile thead th.num { white-space: normal; }
      /* Wide tables scroll sideways with the first column held in place. */
      .tableau-defile tbody th[scope='row'], .tableau-defile thead th:first-child {
        position: sticky; left: 0; z-index: 1; background: var(--bs-card-bg, var(--bs-body-bg)); }
      .tableau-defile thead th:first-child { z-index: 2; }
      /* Phones: a title that leaves room for the menu button, and compact
         headline figures, so that the first chart shows on the first screen. */
      @media (max-width: 575.98px) {
        .navbar-brand { font-size: 1.05rem; white-space: normal; line-height: 1.2;
                        max-width: calc(100% - 4.5rem); }
        body .bslib-value-box { min-height: 0 !important; ---bslib-value-box-showcase-w: 3.75rem; }
        body .bslib-value-box .value-box-area { padding: .7rem .9rem .7rem .25rem; }
        body .bslib-value-box .value-box-title { font-size: .9rem; margin-bottom: 0; }
        body .bslib-value-box .value-box-value { font-size: 1.5rem; }
        body .bslib-value-box .value-box-showcase { padding: .5rem; }
        body .bslib-value-box .value-box-showcase svg { width: 1.75rem !important; height: 1.75rem !important; }
        /* The map: no empty band above and below it. */
        body .card:has(#carte-carte) { min-height: 0 !important; }
        body #carte-carte { min-height: 280px !important; }
        .bslib-grid { gap: .6rem !important; }
        .tableau-defile { font-size: .9rem; }
        .tableau-defile tbody th[scope='row'] { min-width: 8.5rem; }
      }
    ")
}

# What the page declares: bslib's default Bootstrap 5 theme, which bslib
# recognises and serves precompiled (no Sass at start-up). publier.R swaps it
# for theme_source() to compile the static files.
theme_app <- function() bslib::bs_theme(version = 5)

# Colours of the service ladder (from safest to least safe) and of the map.
COULEURS_ECHELLE <- c(safely = "#295489", basic = "#7DA4D4", limited = "#e9c46a",
                      unimproved = "#e07a5f", surface = "#b23a48")
ECHELLE_CARTE <- list(list(0, "#7a1022"), list(0.25, "#c0392b"), list(0.5, "#f1a07c"),
                      list(0.7, "#f6e3c7"), list(0.85, "#9cc3e6"), list(1, "#1f4e89"))
