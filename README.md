# Safe drinking water, country by country (R Shiny)

**Question:** where does each country stand on safe drinking water, and is universal access by 2030 still within reach?

An R Shiny app on the WHO/UNICEF JMP estimates for 235 countries and territories, 2000 to 2024: four views, English and French, light and dark themes. Published as a static site with shinylive: R runs in the visitor's browser through webR, with no server.

- Live app: https://mohamedbougrara.github.io/portfolio-Bougrara-Mohamed/shiny-eau/
- Case study: https://mohamedbougrara.github.io/portfolio-Bougrara-Mohamed/eau-potable-shiny.html
- First version of the map, in JavaScript with D3: https://mohamedbougrara.github.io/portfolio-Bougrara-Mohamed/eau-potable.html

## Key findings

- In 2024, **73.7 %** of the world's population has safely managed drinking water at home; **2.14 billion** people do not.
- At the 2015-2024 pace, the world would reach 99 % in **2062**, 32 years after the 2030 target.
- Performance work on the published app: in my measurements on the live site (mean of 5 loads), the map appeared after **9.4 s** instead of **60.1 s**, and the interface after 8.5 s instead of 28.9 s. A first visit on an ordinary connection can still take 10 to 40 s, because R is downloaded into the browser.

## How it works

- **Data.** `preparer.R` turns the JMP tables into one compact file, `data/eau.rds`. Shares are recomputed from numbers of people, so a region weighs what its population weighs. It checks the world headline (73.7 %, 2.14 billion) before writing.
- **App.** One Shiny module per tab, each with its own namespace: world map, country profile, regions and 2030, ranking (with CSV export). The map returns the clicked country; the country profile exposes a function to select it. The address names the language, the tab and the country, so a profile can be shared.
- **Charts.** A custom Shiny output: R builds each figure as a list, `www/graphique.js` draws it with plotly.js and sends clicks back to R (the plotly R package would have added 95 MB to load in the browser).
- **Reactivity.** Cached reactives (`bindCache`), debounced search and comparison.
- **Tests.** 31 checks: 18 on the calculations with testthat, 13 on the modules with `testServer`.
- **Publication.** `publier.R` compiles the theme and renders the page once, serves CSS and JavaScript as static files, and exports the site with shinylive.

## How to run

From this folder, in a UTF-8 locale (for example `LC_ALL=C.UTF-8`):

```bash
Rscript -e 'install.packages(c("shiny", "bslib", "testthat"))'
Rscript -e 'shiny::runApp(launch.browser = TRUE)'
Rscript tests/testthat.R
```

To export the static site: `Rscript publier.R` (writes `shiny-eau/`; needs `shinylive`, `callr`, `httpuv`, and the `shiny` and `bslib` versions that webR runs, checked by the script).

`data/eau.rds` is committed, so the app runs as is. `Rscript preparer.R <source>` rebuilds it, and `www/monde.geojson`, from intermediate tables that are not in this repository: `<source>/donnees/` (`access.csv`, `criteria.csv`, `areas.csv`, `gdp.csv`, prepared from the Our World in Data catalogue) and `<source>/carte/carte_data.js` (Natural Earth shapes).

## Folder

```
.
├── app.R                  page, server, links between the modules
├── R/
│   ├── donnees.R          data loaded once, pure functions (tested)
│   ├── mod_carte.R        world map module
│   ├── mod_pays.R         country profile module
│   ├── mod_regions.R      regions and 2030 module
│   ├── mod_classement.R   ranking module, CSV export
│   ├── graphique.R        custom Shiny output for plotly.js
│   ├── i18n.R             English and French strings, number formats
│   ├── ui.R, theme.R      page layout, bslib theme
│   └── statiques.R, tableau.R, icones.R
├── www/                   plotly.js, chart binding, country shapes, compiled theme
├── data/eau.rds           prepared JMP data (binary, about 0.8 MB)
├── tests/                 testthat and testServer
├── preparer.R             builds data/eau.rds and www/monde.geojson
├── publier.R              exports the static site with shinylive
├── chargement.html        loading screen shown while R starts in the browser
└── DATA-LICENSE.md
```

## Limitations

- First load: 10 to 40 s depending on the connection, while R is downloaded and set up in the browser.
- Countries without a national estimate stay grey on the map. World, regional and income-group figures are the JMP's own aggregates, which impute countries without an estimate.
- The 2030 view extends each area's average yearly gain over 2015-2024 in a straight line, up to 99 %: a pace, not a forecast.
- `data/eau.rds` cannot be rebuilt from this repository alone (see "How to run").

## Data and licences

- **Drinking water estimates:** World Health Organization/UNICEF Joint Monitoring Programme for Water Supply, Sanitation and Hygiene (JMP), December 2025 update, SDG indicator 6.1.1, as republished by Our World in Data. Source: https://washdata.org/
- **Areas:** continents from Our World in Data; income groups from the World Bank income classification, via Our World in Data.
- **Country shapes:** Natural Earth.

Licence terms for the data files in this repository are in [DATA-LICENSE.md](DATA-LICENSE.md). Third-party files in `www/` (plotly.js, Bootstrap and the other compiled theme files) keep their own licences, stated in their headers.
