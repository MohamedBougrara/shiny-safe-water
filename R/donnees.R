# donnees.R
# Data loaded once per R process, shared by every session, and the pure
# functions the modules call. Pure functions take data in and return data out:
# they are tested without starting the app (tests/testthat).

`%||%` <- function(a, b) if (is.null(a)) b else a

D      <- readRDS(file.path("data", "eau.rds"))
ANNEES <- range(D$eau$year)

PAYS <- D$zones[D$zones$type == "Country", ]
PAYS <- PAYS[order(PAYS$area), ]
CONTINENTS <- sort(unique(stats::na.omit(PAYS$continent)))
REVENUS <- unique(PAYS$income[order(PAYS$income_order)])
REVENUS <- REVENUS[!is.na(REVENUS)]

INDICATEURS <- c("safely", "basic_plus", "surface")
MILIEUX <- c("Total", "Urban", "Rural")

# Country choices for a select input: names shown, ISO3 codes returned.
choix_pays <- function() stats::setNames(PAYS$code, PAYS$area)

# Value of one indicator for every country, for one year and one residence.
carte_valeurs <- function(eau, indicateur, milieu, annee) {
  stopifnot(indicateur %in% INDICATEURS, milieu %in% MILIEUX)
  d <- eau[eau$year == annee & eau$residence == milieu & eau$code %in% PAYS$code,
           c("code", indicateur, "population")]
  names(d)[2] <- "valeur"
  merge(PAYS[, c("code", "area", "continent", "income")], d, by = "code", all.x = TRUE)
}

# The n countries where access is lowest for one indicator: the lowest
# shares, or the highest for surface water (a high share means low access).
acces_le_plus_faible <- function(valeurs, indicateur, n = 5) {
  d <- valeurs[!is.na(valeurs$valeur), ]
  d <- d[order(if (indicateur == "surface") -d$valeur else d$valeur, d$area), ]
  utils::head(d, n)
}

# Time series of one area (all residences).
serie <- function(eau, code) {
  d <- eau[eau$code == code, ]
  d[order(d$residence, d$year), ]
}

# Latest year with a value, and change since 2015 (or the first year after).
derniere <- function(eau, code, indicateur = "safely", milieu = "Total") {
  d <- eau[eau$code == code & eau$residence == milieu & !is.na(eau[[indicateur]]), c("year", indicateur)]
  if (!nrow(d)) return(list(annee = NA, valeur = NA, evolution = NA, depuis = NA))
  d <- d[order(d$year), ]
  base <- d[d$year >= 2015, ][1, ]
  fin <- d[nrow(d), ]
  list(annee = fin$year, valeur = fin[[indicateur]],
       evolution = if (is.na(base$year) || base$year == fin$year) NA else fin[[indicateur]] - base[[indicateur]],
       depuis = base$year)
}

# The 2015-2024 pace continued until 99 %, the JMP threshold for universal
# access. Same method as the Power BI report (straight line between the two
# years): it gives 2062 for the world.
projection <- function(eau, code, debut = 2015, fin = 2024, cible = 99) {
  v <- function(a) eau$safely[eau$code == code & eau$year == a & eau$residence == "Total"]
  s0 <- v(debut); s1 <- v(fin)
  if (!length(s0) || !length(s1) || is.na(s0) || is.na(s1)) return(list(rythme = NA, annee = NA, etat = "inconnu"))
  rythme <- (s1 - s0) / (fin - debut)
  if (s1 >= cible) return(list(rythme = rythme, annee = fin, etat = "atteint"))
  if (rythme <= 0) return(list(rythme = rythme, annee = NA, etat = "jamais"))
  list(rythme = rythme, annee = ceiling(fin + (cible - s1) / rythme), etat = "projete")
}

# Ranking table for one year, with the filters of the Ranking tab.
classement <- function(eau, annee, continent = NULL, revenu = NULL) {
  d <- eau[eau$year == annee & eau$residence == "Total" & eau$code %in% PAYS$code,
           c("code", "safely", "basic_plus", "surface", "population")]
  base <- eau[eau$year == 2015 & eau$residence == "Total", c("code", "safely")]
  names(base)[2] <- "safely_2015"
  d <- merge(d, base, by = "code", all.x = TRUE)
  d$evolution <- d$safely - d$safely_2015
  d <- merge(PAYS[, c("code", "area", "continent", "income", "income_order")], d, by = "code")
  if (length(continent)) d <- d[d$continent %in% continent, ]
  if (length(revenu)) d <- d[d$income %in% revenu, ]
  d[order(-d$safely, -d$basic_plus, d$area, na.last = TRUE), ]
}

# Regional aggregates published by the JMP (world, SDG regions, income groups).
regions <- function(eau, type = c("SDG region", "Income group")) {
  type <- match.arg(type)
  z <- D$zones[D$zones$type %in% c(type, "World"), c("code", "area", "type", "order")]
  d <- eau[eau$residence == "Total" & eau$code %in% z$code, c("code", "year", "safely")]
  merge(z, d, by = "code")
}
