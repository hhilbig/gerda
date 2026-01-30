# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Build & Check Commands

- **Full check:** `devtools::check()` or `R CMD build . && R CMD check gerda_*.tar.gz`
- **Run all tests:** `devtools::test()`
- **Run a single test file:** `testthat::test_file("tests/testthat/test-load_gerda_web.R")`
- **Regenerate docs:** `devtools::document()`
- **Build vignettes:** `devtools::build_vignettes()`

## Architecture

gerda is an R package providing tools to download and analyze German election data (1953–2025). It covers local, state, and federal elections at various geographic levels.

### Key design points

- **12 exported functions** across 6 source files
- External data loaded on-demand from GitHub (`awiedem/german_election_data`); not bundled in the package
- Internal datasets stored in `R/sysdata.rda` (covariates, census, structural data, codebooks, party lookup table)
- Data flow: list available datasets → load from web → optionally add covariates, census data, structural data, or map parties via crosswalk
- Dependencies: dplyr, knitr, readr, stats, stringdist, tibble

### Source files

| File | Purpose |
|------|---------|
| `R/load_gerda_web.R` | Downloads datasets; contains embedded data dictionary with GitHub URLs |
| `R/gerda_covariates.R` | Three functions for county-level INKAR covariate access and merging |
| `R/gerda_census.R` | Three functions for municipality-level Census 2022 data access and merging |
| `R/gerda_strukturdaten.R` | Three functions for county-level Bundeswahlleiter structural data access and merging |
| `R/party_crosswalk.R` | Maps GERDA party names to ParlGov attributes via internal lookup table |
| `R/gerda_data_list.R` | Lists available datasets with descriptions |

## Testing

- testthat (edition 3), 6 test files in `tests/testthat/`
- Tests cover parameter validation, fuzzy matching, edge cases, and integration workflows

## Important Conventions

- **Roxygen2** generates all documentation. Run `devtools::document()` after changing any roxygen comments.
- **NAMESPACE is auto-generated** — never edit by hand.
- `R/sysdata.rda` contains internal datasets used by exported functions.
- NSE variables are declared via `utils::globalVariables()` to avoid R CMD check NOTEs.
- Data is fetched from GitHub at runtime — the package contains no bundled election data.
- **Never generate placeholder data with random values.** Internal datasets in `R/sysdata.rda` must contain real data sourced from the scripts in `excluded_code/`. If real data is not yet available, leave the data prep script with a `stop()` and document what needs to be downloaded.
