# Data licence

This file covers the data in this repository, not the code.

## data/eau.rds

Derived from the WHO/UNICEF JMP estimates:

> World Health Organization/UNICEF Joint Monitoring Programme for Water Supply, Sanitation and Hygiene (2025). Estimates for drinking water, sanitation and hygiene services by country (2000-2024), https://washdata.org/data

Retrieved through Our World in Data, whose catalogue lists the licence of these estimates as **CC BY-NC-SA 3.0 IGO**: https://creativecommons.org/licenses/by-nc-sa/3.0/igo/

Changes made: numbers of people per service level were aggregated by area, year and residence, and shares were recomputed from them (see `preparer.R`). `data/eau.rds` is shared under the same licence, CC BY-NC-SA 3.0 IGO.

The file also holds area attributes: continents (Our World in Data) and income groups (World Bank income classification, via Our World in Data).

## www/monde.geojson

Country shapes from Natural Earth (1:110m), which is in the public domain. Coordinates were rounded, and a few shapes were removed, merged or split to match the JMP country list.
