# Pure functions: the figures the app shows must match the Power BI report.

test_that("the world figures match the report", {
  w <- D$eau[D$eau$code == "WLD" & D$eau$year == 2024 & D$eau$residence == "Total", ]
  expect_equal(round(w$safely, 1), 73.7)
  expect_equal(round(w$without_safe / 1e9, 2), 2.14)
})

test_that("the 2015-2024 pace gives 2062 for the world", {
  p <- projection(D$eau, "WLD")
  expect_equal(p$etat, "projete")
  expect_equal(p$annee, 2062)
  expect_equal(round(p$rythme, 2), 0.67)
})

test_that("a country already above 99 % is reported as such", {
  expect_equal(projection(D$eau, "FRA")$etat, "atteint")
})

test_that("shares of the service ladder add up to 100 %", {
  d <- D$eau[!is.na(D$eau$safely), ]
  total <- d$safely + d$basic + d$limited + d$unimproved + d$surface
  expect_true(all(abs(total - 100) < 1e-6))
})

test_that("the map has one row per country, with or without an estimate", {
  v <- carte_valeurs(D$eau, "safely", "Total", 2024)
  expect_equal(nrow(v), nrow(PAYS))
  expect_true(any(is.na(v$valeur)))          # countries without estimate stay, in grey
  expect_error(carte_valeurs(D$eau, "nope", "Total", 2024))
})

test_that("the ranking filters by continent and income group", {
  r <- classement(D$eau, 2024, continent = "Africa", revenu = "Low income")
  expect_gt(nrow(r), 0)
  expect_true(all(r$continent == "Africa" & r$income == "Low income"))
  expect_false(is.unsorted(rev(stats::na.omit(r$safely))))   # best first
})

test_that("the countries with the lowest access follow the indicator", {
  v <- carte_valeurs(D$eau, "safely", "Total", 2024)
  bas <- acces_le_plus_faible(v, "safely")
  expect_equal(nrow(bas), 5)
  expect_equal(bas$valeur[1], min(v$valeur, na.rm = TRUE))      # lowest share first
  s <- carte_valeurs(D$eau, "surface", "Total", 2024)
  expect_equal(acces_le_plus_faible(s, "surface")$valeur[1], max(s$valeur, na.rm = TRUE))  # surface water: highest first
})

test_that("the sentence that reads a country gives its level and where its pace leads", {
  phrase <- lecture_pays("SEN", derniere(D$eau, "SEN"), projection(D$eau, "SEN"), "en")
  expect_match(phrase, "Senegal: 27.2% .* in 2024", perl = TRUE)
  expect_match(phrase, "\\+2.8 points since 2015")
})
