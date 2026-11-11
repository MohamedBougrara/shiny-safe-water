# i18n.R
# Every visible string, in English and French. The language is a reactive
# value: switching it re-renders the labels, the charts and the table without
# reloading the app or losing the user's selections.

TEXTES <- list(
  en = list(
    app_title = "Safe drinking water, country by country",
    nav_map = "World map", nav_country = "Country profile", nav_regions = "Regions & 2030",
    nav_table = "Ranking", nav_about = "About",
    indicator = "Indicator", residence = "Where", year = "Year",
    play = "Play the years", pause = "Pause",
    ind_safely = "Safely managed water (safe water at home)",
    ind_basic_plus = "At least basic water (within 30 min)",
    ind_surface = "Surface water (river, lake, pond)",
    res_Total = "Whole country", res_Urban = "Cities", res_Rural = "Countryside",
    world_share = "World, safely managed", people_without = "People without safe water at home",
    countries_data = "Countries with an estimate",
    map_hint = "Click a country to open its profile. Grey: no national estimate.",
    no_estimate = "no estimate",
    country = "Country", compare_with = "Compare with (up to 3)",
    latest = "Latest estimate", since_2015 = "Change since 2015", points = "points",
    ladder_title = "Service ladder, share of the population",
    gap_title = "Safely managed water: cities and countryside",
    tests_title = "The three tests of safe water, latest year",
    compare_title = "Safely managed water, compared",
    lvl_safely = "Safely managed", lvl_basic = "Basic", lvl_limited = "Limited",
    lvl_unimproved = "Unimproved", lvl_surface = "Surface water",
    crit_available = "Available when needed", crit_premises = "On premises",
    crit_uncontaminated = "Free from contamination",
    no_safely = "No safely managed estimate for this country: the chart shows the levels that are known.",
    group_by = "Group by", grp_sdg = "World regions", grp_income = "Income groups",
    regions_title = "Safely managed water since 2000, with the 2030 goal",
    goal = "2030 goal: universal access (99%)",
    pace = "Pace 2015-2024", pts_year = "points a year", reach = "Year it reaches 99%",
    never = "never at this pace", already = "already reached",
    projection_note = paste(
      "Projection: the 2015-2024 pace (straight line between the two years) continued",
      "until the share reaches 99%, the JMP threshold for universal access."),
    filter_continent = "Continent", filter_income = "Income group", all = "All",
    search = "Search a country", download = "Download CSV", sort_by = "Sort by",
    countries = "countries",
    behind = "Lowest access",
    read_level = "%s: %s of people have safely managed water at home in %d.",
    read_change = " That is %s points since %d.",
    read_goal = " At this pace, 99%% would be reached in %d.",
    read_far = " At this pace, 99% would not be reached before 2100.",
    read_reached = " Universal access (99%) is reached.",
    read_never = " At this pace, 99% would never be reached.",
    table_hint = "Click a country to open its profile, an underlined column header to sort.",
    no_match = "No country matches these filters.", col_area = "Country name (A-Z)",
    col_country = "Country", col_continent = "Continent", col_income = "Income group",
    col_safely = "Safely managed", col_basic_plus = "At least basic", col_surface = "Surface water",
    col_change = "Change since 2015", col_population = "Population",
    about_title = "About this app",
    about_data = paste(
      "Data: WHO/UNICEF Joint Monitoring Programme (JMP), December 2025 update,",
      "SDG indicator 6.1.1, as republished by Our World in Data. Shares are",
      "recomputed from numbers of people: a region weighs what its population weighs."),
    about_build = paste(
      "Built in R with Shiny and bslib, charts drawn with plotly.js, by Mohamed Bougrara. The app runs",
      "entirely in your browser thanks to shinylive and webR: no server, no tracking."),
    about_skills = "What the code shows",
    skills = c(
      "Shiny modules: one module per tab, each with its own namespace, tested with testServer.",
      "Modules talk to each other: a click on the map or in the ranking opens the country profile.",
      "A link that can be shared: the address names the language, the tab and the country.",
      "A custom Shiny output binding for plotly.js: R builds each figure, JavaScript draws it and sends clicks back.",
      "Reactive graph kept lean: cached reactives (bindCache), debounced search and comparison.",
      "Bilingual interface switched reactively, without reloading.",
      "Input validation with clear messages when a country has no estimate.",
      "Light and dark themes with bslib, matched to the portfolio's colours.",
      "CSV export of the filtered ranking.",
      "Runs in the browser with webR, tuned to load fast: page rendered and theme compiled once at publication, CSS and JavaScript served as static files, dependencies kept to shiny and bslib."),
    lang_label = "Language", loading = "Loading", source_short = "Source: WHO/UNICEF JMP 2025"
  ),
  fr = list(
    app_title = "L'eau potable, pays par pays",
    nav_map = "Carte du monde", nav_country = "Fiche pays", nav_regions = "Régions et 2030",
    nav_table = "Classement", nav_about = "À propos",
    indicator = "Indicateur", residence = "Milieu", year = "Année",
    play = "Faire défiler les années", pause = "Pause",
    ind_safely = "Eau gérée en toute sécurité (eau potable chez soi)",
    ind_basic_plus = "Au moins un service de base (à moins de 30 min)",
    ind_surface = "Eau de surface (rivière, lac, mare)",
    res_Total = "Tout le pays", res_Urban = "Villes", res_Rural = "Campagnes",
    world_share = "Monde, eau gérée en toute sécurité", people_without = "Personnes sans eau potable chez elles",
    countries_data = "Pays avec une estimation",
    map_hint = "Cliquez sur un pays pour ouvrir sa fiche. En gris : pas d'estimation nationale.",
    no_estimate = "pas d'estimation",
    country = "Pays", compare_with = "Comparer avec (3 au plus)",
    latest = "Dernière estimation", since_2015 = "Évolution depuis 2015", points = "points",
    ladder_title = "Échelle de service, part de la population",
    gap_title = "Eau gérée en toute sécurité : villes et campagnes",
    tests_title = "Les trois critères de l'eau potable, dernière année",
    compare_title = "Eau gérée en toute sécurité, comparée",
    lvl_safely = "Gérée en toute sécurité", lvl_basic = "Base", lvl_limited = "Limitée",
    lvl_unimproved = "Non améliorée", lvl_surface = "Eau de surface",
    crit_available = "Disponible au besoin", crit_premises = "Au domicile",
    crit_uncontaminated = "Exempte de contamination",
    no_safely = "Pas d'estimation de l'eau gérée en toute sécurité pour ce pays : le graphique montre les niveaux connus.",
    group_by = "Regrouper par", grp_sdg = "Régions du monde", grp_income = "Groupes de revenu",
    regions_title = "Eau gérée en toute sécurité depuis 2000, et l'objectif 2030",
    goal = "Objectif 2030 : accès universel (99 %)",
    pace = "Rythme 2015-2024", pts_year = "points par an", reach = "Année où il atteint 99 %",
    never = "jamais à ce rythme", already = "déjà atteint",
    projection_note = paste(
      "Projection : le rythme 2015-2024 (droite entre les deux années) prolongé",
      "jusqu'à 99 %, le seuil d'accès universel retenu par le JMP."),
    filter_continent = "Continent", filter_income = "Groupe de revenu", all = "Tous",
    search = "Chercher un pays", download = "Télécharger en CSV", sort_by = "Trier par",
    countries = "pays",
    behind = "Accès le plus faible",
    read_level = "%s : %s des habitants ont de l'eau gérée en toute sécurité chez eux en %d.",
    read_change = " Soit %s points depuis %d.",
    read_goal = " À ce rythme, 99 %% seraient atteints en %d.",
    read_far = " À ce rythme, 99 % ne seraient pas atteints avant 2100.",
    read_reached = " L'accès universel (99 %) est atteint.",
    read_never = " À ce rythme, 99 % ne seraient jamais atteints.",
    table_hint = "Cliquez sur un pays pour ouvrir sa fiche, sur un en-tête souligné pour trier.",
    no_match = "Aucun pays ne correspond à ces filtres.", col_area = "Nom du pays (A-Z)",
    col_country = "Pays", col_continent = "Continent", col_income = "Groupe de revenu",
    col_safely = "Gérée en toute sécurité", col_basic_plus = "Au moins de base", col_surface = "Eau de surface",
    col_change = "Évolution depuis 2015", col_population = "Population",
    about_title = "À propos de cette application",
    about_data = paste(
      "Données : Programme commun OMS/UNICEF de suivi (JMP), mise à jour de décembre 2025,",
      "indicateur ODD 6.1.1, republiées par Our World in Data. Les parts sont recalculées",
      "à partir des nombres de personnes : une région pèse ce que pèse sa population."),
    about_build = paste(
      "Construite en R avec Shiny et bslib, graphiques dessinés avec plotly.js, par Mohamed Bougrara. L'application",
      "tourne entièrement dans votre navigateur grâce à shinylive et webR : ni serveur, ni pistage."),
    about_skills = "Ce que montre le code",
    skills = c(
      "Modules Shiny : un module par onglet, chacun avec son espace de noms, testé avec testServer.",
      "Les modules communiquent : un clic sur la carte ou dans le classement ouvre la fiche du pays.",
      "Un lien partageable : l'adresse nomme la langue, l'onglet et le pays.",
      "Une sortie Shiny sur mesure pour plotly.js : R construit chaque figure, JavaScript la dessine et renvoie les clics.",
      "Graphe réactif sobre : réactifs mis en cache (bindCache), recherche et comparaison temporisées.",
      "Interface bilingue, basculée de façon réactive, sans rechargement.",
      "Validation des entrées, avec un message clair quand un pays n'a pas d'estimation.",
      "Thèmes clair et sombre avec bslib, aux couleurs du portfolio.",
      "Export CSV du classement filtré.",
      "Tourne dans le navigateur avec webR, optimisé pour le chargement : page et thème préparés une fois à la publication, CSS et JavaScript servis en fichiers statiques, dépendances réduites à shiny et bslib."),
    lang_label = "Langue", loading = "Chargement", source_short = "Source : OMS/UNICEF JMP 2025"
  )
)

# Translation helper: tr("nav_map", "fr").
tr <- function(cle, lang = "en") {
  v <- TEXTES[[lang]][[cle]]
  if (is.null(v)) TEXTES$en[[cle]] else v
}

# Continent and income-group names as published, translated for display.
NOMS_FR <- c(
  "Africa" = "Afrique", "Asia" = "Asie", "Europe" = "Europe", "North America" = "Amérique du Nord",
  "South America" = "Amérique du Sud", "Oceania" = "Océanie",
  "Low income" = "Revenu faible", "Lower-middle income" = "Revenu intermédiaire inférieur",
  "Upper-middle income" = "Revenu intermédiaire supérieur", "High income" = "Revenu élevé",
  "World" = "Monde", "Australia & New Zealand" = "Australie et Nouvelle-Zélande",
  "Central & South Asia" = "Asie centrale et du Sud", "East & South-East Asia" = "Asie de l'Est et du Sud-Est",
  "Europe & N. America" = "Europe et Amérique du Nord", "Latin America & Caribbean" = "Amérique latine et Caraïbes",
  "N. Africa & W. Asia" = "Afrique du Nord et Asie de l'Ouest", "Oceania" = "Océanie",
  "Sub-Saharan Africa" = "Afrique subsaharienne"
)
nom_groupe <- function(x, lang) if (lang == "fr") unname(ifelse(x %in% names(NOMS_FR), NOMS_FR[x], x)) else x

# Number formats in each language: 8 160 287 632 / 8,160,287,632 ; 73,7 % / 73.7%.
fmt_nb <- function(x, lang) formatC(x, format = "d", big.mark = if (lang == "fr") " " else ",")
fmt_pc <- function(x, lang, d = 1) {
  ifelse(is.na(x), "-", if (lang == "fr") paste0(formatC(x, format = "f", digits = d, decimal.mark = ","), " %")
         else paste0(formatC(x, format = "f", digits = d), "%"))
}
fmt_mds <- function(x, lang) {
  if (lang == "fr") paste0(formatC(x / 1e9, format = "f", digits = 2, decimal.mark = ","), " milliards")
  else paste0(formatC(x / 1e9, format = "f", digits = 2), " billion")
}

# A change in points with its sign; -0.04 shows as 0.0, not -0.0.
fmt_pts <- function(v, lang) {
  v <- round(v, 1)
  v[!is.na(v) & v == 0] <- 0
  ifelse(is.na(v), "-", paste0(ifelse(!is.na(v) & v > 0, "+", ""),
                               formatC(v, format = "f", digits = 1, decimal.mark = if (lang == "fr") "," else ".")))
}

# One sentence that reads a country: its latest level, its change since 2015
# and where its pace leads (see projection() in donnees.R).
lecture_pays <- function(code, chiffres, proj, lang) {
  if (is.na(chiffres$annee)) return(tr("no_safely", lang))
  paste0(
    sprintf(tr("read_level", lang), PAYS$area[PAYS$code == code], fmt_pc(chiffres$valeur, lang), chiffres$annee),
    if (!is.na(chiffres$evolution)) sprintf(tr("read_change", lang), fmt_pts(chiffres$evolution, lang), chiffres$depuis),
    switch(proj$etat, projete = if (proj$annee > 2100) tr("read_far", lang) else sprintf(tr("read_goal", lang), proj$annee), atteint = tr("read_reached", lang),
           jamais = tr("read_never", lang), ""))
}
