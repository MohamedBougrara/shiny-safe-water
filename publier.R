# publier.R
# Exports the app as a static site with shinylive: R runs in the visitor's
# browser through webR, so the portfolio (static hosting) can serve it.
# Only the files the app needs are exported (no tests, no preparation script).
#
# Usage, from this folder:  Rscript publier.R [output folder]
#   default output: ./shiny-eau
#   needs the bslib and shiny versions that webR runs (checked below), for
#   instance installed in a separate library: R_LIBS=<library> Rscript publier.R

args <- commandArgs(trailingOnly = TRUE)
sortie <- normalizePath(if (length(args)) args[1] else "shiny-eau", mustWork = FALSE)

source(file.path("R", "statiques.R"))

# The R library that webR runs in the browser, as shinylive ships it: one
# archive, and the position of each file in it.
webr <- file.path(shinylive::assets_ensure(), "shinylive", "webr")
index_webr <- jsonlite::fromJSON(file.path(webr, "library.js.metadata"))$files
con <- gzfile(file.path(webr, "library.data.gz"), "rb")
archive_webr <- readBin(con, "raw", max(index_webr$end))
close(con)
fichier_webr <- function(chemin) {
  f <- index_webr[index_webr$filename == paste0("/", chemin), ]
  if (nrow(f) != 1) stop(chemin, " is not in the webR library")
  archive_webr[(f$start + 1):f$end]
}
version_webr <- function(paquet) {
  desc <- strsplit(rawToChar(fichier_webr(file.path(paquet, "DESCRIPTION"))), "\n")[[1]]
  sub("^Version: *", "", grep("^Version:", desc, value = TRUE))
}

# 1. The theme, compiled once here instead of at every visit (see R/theme.R).
# It is compiled with the bslib and shiny versions webR runs, so that the CSS
# matches the JavaScript of the components in the browser.
for (paquet in c("bslib", "shiny")) {
  la_bas <- version_webr(paquet)
  ici <- as.character(utils::packageVersion(paquet))
  # Same major.minor.patch (webR may run a development build, as 1.13.0.8000).
  if (!identical(unlist(package_version(la_bas))[1:3], unlist(package_version(ici))[1:3])) {
    stop(sprintf("webR runs %s %s but this R has %s %s: install %s in a separate library",
                 paquet, la_bas, paquet, ici, paste(unlist(package_version(la_bas))[1:3], collapse = ".")))
  }
}

# The app runs once here, in a separate R process, with the theme itself
# (theme_source) and without the static files; its page lists the CSS that
# bslib and Shiny compiled, downloaded into www/theme/<dependency>/ under the
# name of the dependency each one replaces in the published app.
compilees <- c(bootstrap = "bootstrap", "bslib-component-css" = "bslib-component-css",
               "shiny-sass" = "shiny-css", selectize = "selectize",
               ionRangeSlider = "ionrangeslider-css")
# Starts the app in a separate R process and returns its page.
# compiler = TRUE: with the theme itself and without the static files.
# compiler = FALSE: as it will run under webR, static files included.
page_de_l_app <- function(compiler) {
  port <- httpuv::randomPort()
  serveur <- callr::r_bg(function(port, compiler) {
    for (f in sort(list.files("R", full.names = TRUE))) source(f)
    if (compiler) {
      assign("theme_app", theme_source, envir = globalenv())
      assign("dependances_statiques", function() NULL, envir = globalenv())
    }
    shiny::runApp(source("app.R")$value, port = port, launch.browser = FALSE)
  }, args = list(port, compiler), wd = getwd(), libpath = .libPaths(),
  env = c(callr::rcmd_safe_env(), LC_ALL = "C.UTF-8", if (!compiler) c(EAU_PAGE_PUBLIEE = "1")))
  adresse <- sprintf("http://127.0.0.1:%d/", port)
  page <- NULL
  for (i in 1:120) {
    page <- tryCatch(suppressWarnings(readLines(adresse, warn = FALSE, encoding = "UTF-8")),
                     error = function(e) NULL)
    if (!is.null(page) || !serveur$is_alive()) break
    Sys.sleep(0.5)
  }
  if (is.null(page)) stop("the app did not start:\n", serveur$read_all_error())
  list(page = page, adresse = adresse, serveur = serveur)
}
liens_de <- function(page) {
  sub('^(href|src)="(.*)"$', "\\2", unlist(regmatches(page, gregexpr('(href|src)="[^"]+"', page))))
}
app_compilee <- page_de_l_app(compiler = TRUE)
adresse <- app_compilee$adresse
liens <- liens_de(app_compilee$page)
for (nom in names(compilees)) {
  cible <- compilees[[nom]]
  liens_dep <- grep(sprintf("^%s-[0-9.]+/", nom), liens, value = TRUE)
  fichiers <- sub("^[^/]+/", "", liens_dep)
  if (!setequal(fichiers, FICHIERS_THEME[[cible]])) {
    stop(sprintf("%s: the page lists %s, R/statiques.R expects %s", nom,
                 paste(fichiers, collapse = ", "), paste(FICHIERS_THEME[[cible]], collapse = ", ")))
  }
  dossier <- file.path("www", "theme", cible)
  unlink(dossier, recursive = TRUE)
  dir.create(dossier, recursive = TRUE)
  for (i in seq_along(liens_dep)) {
    utils::download.file(paste0(adresse, liens_dep[i]), file.path(dossier, fichiers[i]),
                         quiet = TRUE, mode = "wb")
  }
}
app_compilee$serveur$kill()
# The web fonts of bslib's default theme (Open Sans, Source Code Pro) are not
# used by this theme: one request less.
css <- file.path("www", "theme", "bootstrap", "bootstrap.min.css")
writeLines(sub('@import url("font.css");', "", readLines(css, warn = FALSE), fixed = TRUE), css)

# 2. The app.
app <- file.path(tempdir(), "app")
unlink(app, recursive = TRUE)
dir.create(app)
file.copy("app.R", app)
# www/ is not part of the app bundle: its files (plotly.js, the shapes, the
# chart binding) are published next to the app as static files, so the
# browser downloads them directly, compressed and cached, instead of asking
# R to serve them (see R/graphique.R).
for (d in c("R", "data")) file.copy(d, app, recursive = TRUE)

# The page itself, rendered once here (see app.R): the published app serves it
# as it is. Every file it loads must be one of the static files.
app_publiee <- page_de_l_app(compiler = FALSE)
app_publiee$serveur$kill()
servis_par_r <- grep("^(\\.\\./|#|https?:|data:)", liens_de(app_publiee$page), value = TRUE, invert = TRUE)
if (length(servis_par_r)) {
  stop("the page still loads files that R would serve: ", paste(servis_par_r, collapse = ", "),
       "\nadd them to R/statiques.R")
}
writeLines(app_publiee$page, file.path(app, "data", "page.html"), useBytes = TRUE)

unlink(sortie, recursive = TRUE)
titre <- "Safe drinking water, country by country · Mohamed Bougrara"
shinylive::export(app, sortie, template_params = list(title = titre), quiet = FALSE)

invisible(file.copy(list.files("www", full.names = TRUE), sortie, recursive = TRUE))

# 3. The other files of the page, copied from the webR library (R/statiques.R).
for (nom in names(FICHIERS_WEBR)) {
  dossier <- file.path(sortie, "lib", nom)
  dir.create(dossier, recursive = TRUE)
  for (chemin in FICHIERS_WEBR[[nom]]) writeBin(fichier_webr(chemin), file.path(dossier, basename(chemin)))
}

# The editor view would show the source next to the app: not published.
unlink(file.path(sortie, "edit"), recursive = TRUE)
# Source maps of the webR runtime: only useful in developer tools.
unlink(list.files(sortie, pattern = "\\.map$", recursive = TRUE, full.names = TRUE))

# The page that hosts the app: author, rights, robots directives, and a content
# security policy. webR needs WebAssembly, a service worker and blob: workers;
# nothing is loaded from another site.
csp <- paste(
  "default-src 'self';",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' blob:;",
  "worker-src 'self' blob:; child-src 'self' blob:; frame-src 'self' blob:;",
  "style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:;",
  "connect-src 'self' blob: data:; object-src 'none'; base-uri 'self'; form-action 'self'")
page <- readLines(file.path(sortie, "index.html"), warn = FALSE, encoding = "UTF-8")
entete <- c(
  sprintf('    <meta http-equiv="Content-Security-Policy" content="%s">', csp),
  '    <meta name="author" content="Mohamed Bougrara">',
  '    <meta name="description" content="R Shiny app: safe drinking water in 235 countries and territories, 2000-2024 (WHO/UNICEF JMP).">',
  '    <meta name="robots" content="noai, noimageai">',
  '    <meta name="rights" content="&copy; Mohamed Bougrara. All rights reserved.">')
# Fetched while R starts, so that they are in the browser cache when needed:
# - the static files of the page (www/: theme, plotly.js, shapes; lib/);
# - the R packages that webR mounts on demand (translations, parallel,
#   tcltk): shinylive lists the installed packages before starting the app,
#   which makes webR download them one after the other, R waiting meanwhile.
statiques <- c(list.files("www", recursive = TRUE),
               file.path("lib", list.files(file.path(sortie, "lib"), recursive = TRUE)))
a_la_demande <- file.path("shinylive", "webr", "vfs", "usr", "lib", "R", "library")
a_la_demande <- file.path(a_la_demande, list.files(file.path(sortie, a_la_demande),
                                                   pattern = "\\.(data\\.gz|js\\.metadata)$"))
entete <- c(entete, sprintf('    <link rel="prefetch" href="%s">', c(statiques, a_la_demande)))
i <- grep('<meta charset="UTF-8" />', page, fixed = TRUE)[1]
page <- append(page, entete, after = i)
# The loading screen, shown while R starts (chargement.html).
i <- grep("<body>", page, fixed = TRUE)[1]
page <- append(page, readLines("chargement.html", warn = FALSE, encoding = "UTF-8"), after = i)
writeLines(page, file.path(sortie, "index.html"), useBytes = TRUE)

taille <- sum(file.info(list.files(sortie, recursive = TRUE, full.names = TRUE))$size)
cat(sprintf("Exported to %s: %d files, %.1f MB\n", sortie,
            length(list.files(sortie, recursive = TRUE)), taille / 1e6))
