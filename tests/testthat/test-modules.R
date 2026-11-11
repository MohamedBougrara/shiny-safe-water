# Modules tested with shiny::testServer, without a browser.

test_that("the country module reacts to selectionner() and computes its figures", {
  shiny::testServer(pays_server, args = list(lang = shiny::reactive("en"), sombre = shiny::reactive(FALSE)), {
    session$setInputs(pays = "SEN", comparer = c("MAR"))
    expect_equal(chiffres()$annee, 2024)
    expect_equal(output$v_derniere, "27.2%")
    # what the parent calls on a map click
    session$returned$selectionner("FRA")
    session$setInputs(pays = "FRA")
    expect_equal(code(), "FRA")
    expect_match(output$v_derniere, "^9")
  })
})

test_that("the ranking module exports exactly the filtered rows", {
  shiny::testServer(classement_server, args = list(lang = shiny::reactive("fr"), sombre = shiny::reactive(FALSE)), {
    session$setInputs(annee = 2024, continent = "Europe", revenu = NULL)
    n <- nrow(donnees())
    f <- output$csv
    csv <- utils::read.csv(f)
    expect_equal(nrow(csv), n)
    expect_true(all(csv$continent == "Europe"))
    expect_match(output$titre, "Classement")
    # a click on a column header sorts, a click on a country is returned
    session$setInputs(tri = "population")
    expect_equal(donnees()$code[1], "RUS")
    session$setInputs(clic = "SEN")
    expect_equal(session$returned(), "SEN")
  })
})

test_that("the map module returns NULL until a country is clicked, and shares its year", {
  annee <- shiny::reactiveVal(2024)
  shiny::testServer(carte_server, args = list(lang = shiny::reactive("fr"), sombre = shiny::reactive(TRUE),
                                              annee = annee), {
    session$setInputs(indicateur = "safely", milieu = "Total", annee = 2024)
    expect_null(session$returned())
    expect_equal(output$v_monde, "73,7 %")
    session$setInputs(annee = 2010)
    expect_equal(shiny::isolate(annee()), 2010)      # the ranking and the profile will follow
    session$setInputs(liste_click = "TCD")
    expect_equal(session$returned(), "TCD")
  })
})
