# preparer.R
# Builds the compact data the Shiny app reads (data/eau.rds, www/monde.geojson)
# from the tables already prepared for the Power BI report
# (<source>/donnees: access.csv, criteria.csv, areas.csv, gdp.csv; WHO/UNICEF
# JMP estimates, December 2025 update, as republished by Our World in Data)
# and from the Natural Earth shapes of the interactive map
# (<source>/carte/carte_data.js).
#
# Shares are recomputed from numbers of people, as in the report: a region
# weighs what its population weighs, it is not an average of countries.
#
# Usage, from this folder:  Rscript preparer.R <source>

suppressPackageStartupMessages(library(jsonlite))

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("usage: Rscript preparer.R <source folder>")
src <- args[1]
lire <- function(f) read.csv(file.path(src, "donnees", f), check.names = FALSE,
                             stringsAsFactors = FALSE)

access   <- lire("access.csv")
criteria <- lire("criteria.csv")
areas    <- lire("areas.csv")
gdp      <- lire("gdp.csv")
names(access)   <- c("code", "year", "residence", "level", "people", "sm_estimated")
names(criteria) <- c("code", "year", "residence", "criterion", "people", "population")
names(areas)    <- c("code", "area", "type", "order", "continent", "income", "income_order")
names(gdp)      <- c("code", "year", "gdp")

# ── One row per area, year and residence: population and shares ─────────────
# The service ladder: safely managed, basic, limited, unimproved, surface water.
# When the JMP cannot split safely managed from basic, it publishes
# « At least basic, not split »: safely managed then stays unknown (NA), but
# « at least basic » is still known.
access$sm_estimated <- access$sm_estimated %in% c("True", TRUE)
cle <- interaction(access$code, access$year, access$residence, drop = TRUE, sep = "|")
par_cle <- split(access, cle)

ligne <- function(d) {
  p <- function(niveau) sum(d$people[d$level == niveau])
  pop <- sum(d$people)
  sm_known <- any(d$level == "Safely managed") && all(d$sm_estimated)
  data.frame(
    code = d$code[1], year = d$year[1], residence = d$residence[1],
    population   = pop,
    safely       = if (sm_known) 100 * p("Safely managed") / pop else NA_real_,
    basic_plus   = 100 * (p("Safely managed") + p("Basic") + p("At least basic, not split")) / pop,
    limited      = 100 * p("Limited") / pop,
    unimproved   = 100 * p("Unimproved") / pop,
    surface      = 100 * p("Surface water") / pop,
    without_safe = if (sm_known) pop - p("Safely managed") else NA_real_
  )
}
eau <- do.call(rbind, lapply(par_cle, ligne))
rownames(eau) <- NULL
eau$basic <- ifelse(is.na(eau$safely), NA_real_, eau$basic_plus - eau$safely)

# ── The three tests of safely managed water (total population only) ────────
crit <- criteria[criteria$residence == "Total", ]
crit$share <- 100 * crit$people / crit$population
crit$criterion <- c("Available when needed" = "available",
                    "Accessible on premises" = "premises",
                    "Free from contamination" = "uncontaminated")[crit$criterion]
crit_wide <- reshape(crit[, c("code", "year", "criterion", "share")],
                     idvar = c("code", "year"), timevar = "criterion", direction = "wide")
names(crit_wide) <- sub("^share\\.", "", names(crit_wide))

# ── Area dimension ──────────────────────────────────────────────────────────
areas$continent[areas$continent == ""] <- NA
areas$income[areas$income %in% c("", "Not classified")] <- NA

# ── Checks before writing: the app's headline must match the report ─────────
monde24 <- eau[eau$code == "WLD" & eau$year == 2024 & eau$residence == "Total", ]
stopifnot(abs(monde24$safely - 73.7) < 0.05)          # 73.7 % in the report
stopifnot(abs(monde24$without_safe / 1e9 - 2.14) < 0.01)
stopifnot(nrow(merge(eau, areas, by = "code")) == nrow(eau))  # every row has an area
stopifnot(all(eau$population > 0))

# gzip, not xz: under webR (in the browser) decompressing xz costs more
# than the bytes it saves; gzip is read almost as fast as raw data.
saveRDS(list(
  eau      = eau,
  criteres = crit_wide,
  zones    = areas,
  source   = "WHO/UNICEF JMP, December 2025 update (via Our World in Data)"
), file.path("data", "eau.rds"), compress = "gzip")

# ── Country shapes: Natural Earth 1:110m, already simplified for the map ────
js <- readLines(file.path(src, "carte", "carte_data.js"), warn = FALSE, encoding = "UTF-8")
js <- paste(js, collapse = "\n")
debut <- regexpr("window\\.WORLD\\s*=\\s*", js)
reste <- substring(js, debut + attr(debut, "match.length"))
fin <- regexpr(";\\s*window\\.", reste)
# Written as a static file, loaded once by the browser: R never serialises
# the 174 shapes, it only sends codes and values.
monde <- fromJSON(substring(reste, 1, fin - 1), simplifyVector = FALSE)
writeLines(as.character(toJSON(monde, auto_unbox = TRUE, digits = NA)), file.path("www", "monde.geojson"),
           useBytes = TRUE)

cat(sprintf("eau.rds: %d rows (%d areas, %d-%d); monde.geojson: %d shapes\n",
            nrow(eau), length(unique(eau$code)), min(eau$year), max(eau$year),
            length(monde$features)))
