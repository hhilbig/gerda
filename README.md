# GERDA: German Election Data for R

This R package provides data on German elections since 1945, together with helpers for merging socioeconomic covariates. Its downloadable catalog contains 47 datasets covering:

- federal elections at the municipality and county level (1953–2025)
- federal elections at the constituency (Wahlkreis) level (2002–2025), plus a 2021→2025 constituency crosswalk
- state (Landtag) elections at the municipality and constituency (Wahlkreis) levels
- local (municipal) elections (1984–2026), unharmonized and harmonized; the unharmonized file includes council seat counts
- county (Kreistag) elections, plus a county council seat composition panel (2008–2025)
- European Parliament elections at the municipal level
- mayoral elections: results, candidates, and person- and municipality-level panels
- Landrat (county executive) elections: results and candidate-level data
- AGS and county crosswalks between boundary vintages (1990 through 2025)
- municipality and county crosswalk covariates

The package also bundles INKAR county covariates (1995–2022), Zensus 2022 municipality data, and a ParlGov party crosswalk.

GERDA was compiled by Vincent Heddesheimer, Florian Sichart, Andreas Wiedemann, and Hanno Hilbig. See the [GERDA website](https://www.german-elections.com) and the accompanying publication: [doi.org/10.1038/s41597-025-04811-5](https://doi.org/10.1038/s41597-025-04811-5). The package is under active development; comments and bug reports are welcome at <hhilbig@ucdavis.edu> or via GitHub issues.

## Installation

```r
install.packages("gerda")                  # from CRAN
devtools::install_github("hhilbig/gerda")  # development version
```

To install the vignette along with the development version, pass `build_vignettes = TRUE`:

```r
devtools::install_github("hhilbig/gerda", build_vignettes = TRUE)
```

Then read the general introduction with `vignette("gerda")`. For a fail-closed
research workflow designed for coding agents, use
`vignette("agent-workflow")`. CRAN releases ship both vignettes by default.

## Main functions

Data access:

- `gerda_data_list()` prints or returns the full list of available datasets with short descriptions.
- `load_gerda_web(file_name, file_format = "rds")` downloads a dataset from the GERDA GitHub repository. `file_format` is `"rds"` (default) or `"csv"`; both return the same tibble, so the choice only affects download size. `file_name` supports fuzzy matching and suggests close alternatives on misspellings.

Bundled data (no download required):

- `gerda_covariates()` and `gerda_covariates_codebook()` for INKAR county covariates and their codebook.
- `gerda_census()` and `gerda_census_codebook()` for Zensus 2022 municipality data and its codebook.

Merging helpers:

- `add_gerda_covariates(election_data, unmatched = "warn")` merges INKAR county covariates into county- or municipality-level election data. On municipality data, all municipalities in the same Kreis receive identical covariate values.
- `add_gerda_census(election_data, unmatched = "warn")` merges Zensus 2022 into county- or municipality-level election data. For county-level merges, municipality values are aggregated: population-weighted means for shares, sums for counts.
- `gerda_join_diagnostics(x)` returns the machine-readable match report attached by either helper, preserving one report per join in a pipeline.

Party mapping:

- `party_crosswalk(party_gerda, destination)` maps GERDA party names to a column of ParlGov's `view_party` table (e.g. `"left_right"` for ideology scores).

## Choosing an election dataset

Dataset choice affects the research design:

- Use `*_raw` when you need the source-near representation for auditing or custom cleaning.
- Use `*_unharm` for cross-sectional work at the boundaries used in each election. Geographic units can change between elections, so these files generally should not be treated as fixed-boundary panels.
- Use `*_harm` for comparisons over time on a common geography. Suffixes such as `_21`, `_23`, and `_25` identify the target boundary vintage. Choose the vintage that matches the study design; the newest vintage is not automatically the right one.
- Wahlkreis files ending in `_long` contain party vote counts with one row per party. Their wide counterparts contain party vote shares in separate columns. State and federal Wahlkreis boundaries can change between elections.

Use the structured catalog to narrow the choice before downloading:

```r
catalog <- gerda_data_list(print_table = FALSE)
subset(catalog,
       election_type == "federal" &
       geographic_level == "municipality" &
       boundary == "2025")
```

## Example

```r
library(gerda)
library(dplyr)

federal <- load_gerda_web(
  "federal_muni_harm_25",
  on_error = "stop",
  cache = TRUE
) |>
  add_gerda_covariates(unmatched = "error") |>
  add_gerda_census(unmatched = "error")

join_report <- gerda_join_diagnostics(federal)

stopifnot(
  is.data.frame(federal),
  nrow(federal) > 0,
  all(c("ags", "election_year") %in% names(federal)),
  all(join_report$input_rows == join_report$output_rows),
  all(join_report$unexpected_unmatched_rows == 0L)
)
```

The join helpers require five-digit county codes and eight-digit municipality
AGS codes to be character vectors, so lost leading zeros cannot pass silently.
They also reject duplicate reference keys, output-column conflicts, and row
expansion. INKAR years outside 1995--2022 are reported separately from
unexpected unmatched keys. Use `unmatched = "error"` in unattended scripts and
inspect `gerda_join_diagnostics()` immediately after joining.

## County covariates (INKAR, 1995–2022)

`add_gerda_covariates()` appends 30 county-level indicators to federal, state, or local election data. Variables cover demographics, GDP and sectoral structure, unemployment (overall, youth, long-term), education, income, healthcare, childcare, housing, transport, and municipal public finances. Coverage is strongest for 1998–2021; newer indicators are available only for recent years. Use `gerda_covariates_codebook()` for per-variable detail including original INKAR codes and missing-data rates.

## Zensus 2022 (municipality-level)

`add_gerda_census()` appends 14 indicators from the German Zensus 2022. Because the census is a single 2022 snapshot, the same values are attached to all election years; analyses that rely on within-unit variation in these variables are not supported.

Indicators cover population and age structure (under 18, 18–29, 30–49, 50–59, and 60+), migration background, household size, and housing (dwellings, vacancy, ownership, rent per square metre, single-family share). The Destatis source groups ages 60–74 together, so it cannot support separate 50–64 and 65+ measures. Most variables have above 95% municipality coverage. `avg_household_size_census22` is missing for about 12.5% of municipalities because Destatis suppresses small-cell values.

## Deprecations

As of v0.8, the upstream `federal_cty_unharm` columns `ags` and `year` are renamed to the canonical GERDA county-level names `county_code` and `election_year` on load (the deprecated `ags`/`year` duplicates announced in v0.6 have been removed). Use `county_code` and `election_year`, which match the rest of the county-level datasets and work directly with `add_gerda_covariates()`.
