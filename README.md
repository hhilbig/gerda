# GERDA: German Election Data for R

This R package provides data on German elections since 1953, together with helpers for merging socioeconomic covariates. As of v0.6 it exposes 39 datasets covering:

- federal elections at the municipality and county level (1953–2025)
- state (Landtag) elections, unharmonized and harmonized to 2021, 2023, and 2025 boundaries
- local (municipal) elections, unharmonized and harmonized to 2025 boundaries
- county (Kreistag) elections
- European Parliament elections at the municipal level
- mayoral elections: results, candidates, and person- and municipality-level panels
- AGS and county crosswalks between boundary vintages (1990 through 2025)
- INKAR county covariates (1995–2022) and Zensus 2022 municipality data, both bundled
- a ParlGov party crosswalk

GERDA was compiled by Vincent Heddesheimer, Florian Sichart, Andreas Wiedemann, and Hanno Hilbig. See the [GERDA website](https://www.german-elections.com) and the accompanying publication: [doi.org/10.1038/s41597-025-04811-5](https://doi.org/10.1038/s41597-025-04811-5). The package is under active development; comments and bug reports are welcome at <hhilbig@ucdavis.edu> or via GitHub issues.

## Installation

```r
install.packages("gerda")                  # from CRAN
devtools::install_github("hhilbig/gerda")  # development version
```

## Main functions

Data access:

- `gerda_data_list()` prints or returns the full list of available datasets with short descriptions.
- `load_gerda_web(file_name, file_format = "rds")` downloads a dataset from the GERDA GitHub repository. `file_format` is `"rds"` (default) or `"csv"`; both return the same tibble, so the choice only affects download size. `file_name` supports fuzzy matching and suggests close alternatives on misspellings.

Bundled data (no download required):

- `gerda_covariates()` and `gerda_covariates_codebook()` for INKAR county covariates and their codebook.
- `gerda_census()` and `gerda_census_codebook()` for Zensus 2022 municipality data and its codebook.

Merging helpers:

- `add_gerda_covariates(election_data)` merges INKAR county covariates into county- or municipality-level election data. On municipality data, all municipalities in the same Kreis receive identical covariate values.
- `add_gerda_census(election_data)` merges Zensus 2022 into county- or municipality-level election data. For county-level merges, municipality values are aggregated: population-weighted means for shares, sums for counts.

Party mapping:

- `party_crosswalk(party_gerda, destination)` maps GERDA party names to a column of ParlGov's `view_party` table (e.g. `"left_right"` for ideology scores).

## Example

```r
library(gerda)
library(dplyr)

federal <- load_gerda_web("federal_muni_harm_25") |>
  add_gerda_covariates() |>
  add_gerda_census()
```

## County covariates (INKAR, 1995–2022)

`add_gerda_covariates()` appends 30 county-level indicators to federal, state, or local election data. Variables cover demographics, GDP and sectoral structure, unemployment (overall, youth, long-term), education, income, healthcare, childcare, housing, transport, and municipal public finances. Coverage is strongest for 1998–2021; newer indicators are available only for recent years. Use `gerda_covariates_codebook()` for per-variable detail including original INKAR codes and missing-data rates.

## Zensus 2022 (municipality-level)

`add_gerda_census()` appends 14 indicators from the German Zensus 2022. Because the census is a single 2022 snapshot, the same values are attached to all election years; analyses that rely on within-unit variation in these variables are not supported.

Indicators cover population and age structure, migration background, household size, and housing (dwellings, vacancy, ownership, rent per square metre, single-family share). Most variables have above 95% municipality coverage. `avg_household_size_census22` is missing for about 12.5% of municipalities because Destatis suppresses small-cell values.

## Deprecations

As of v0.6, `federal_cty_unharm` exposes both the upstream columns (`ags`, `year`) and the canonical GERDA county-level names (`county_code`, `election_year`). The `ags` and `year` aliases will be removed in v0.7. New code should use `county_code` and `election_year`, which match the rest of the county-level datasets and work directly with `add_gerda_covariates()`.
