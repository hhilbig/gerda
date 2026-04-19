# gerda 0.6.0 (development)

## New Features

* Exposed 25 additional datasets via `load_gerda_web()` and `gerda_data_list()`:
  * **County (Kreistag) elections** (4): `county_elec_unharm`, `county_elec_harm_21`, `county_elec_harm_21_cty`, `county_elec_harm_21_muni`
  * **European Parliament elections** (2): `european_muni_unharm`, `european_muni_harm`
  * **Mayoral elections** (7): `mayoral_unharm`, `mayoral_harm`, `mayoral_candidates`, `mayor_panel`, `mayor_panel_harm`, `mayor_panel_annual`, `mayor_panel_annual_harm`
  * **Boundary-specific harmonizations** (4): `municipal_harm_25`, `state_harm_21`, `state_harm_23`, `state_harm_25`
  * **Additional crosswalks** (7): `ags_1990_to_2023_crosswalk`, `ags_1990_to_2025_crosswalk`, `crosswalk_ags_2021_to_2023`, `crosswalk_ags_2021_2022_to_2023`, `crosswalk_ags_2023_to_2025` (RDS only), `crosswalk_ags_2023_24_to_2025` (RDS only), `crosswalk_ags_2024_to_2025` (RDS only)
  * **Alternative-boundary covariates** (1): `ags_area_pop_emp_2023`

## Deprecations

* `federal_cty_unharm` now also exposes `county_code` and `election_year` columns, matching the schema used by all other county-level GERDA datasets. This allows the dataset to be piped into `add_gerda_covariates()` without manual renaming.
* The original `ags` (5-digit county code) and `year` columns remain for backwards compatibility but are **deprecated** and scheduled for removal in **v0.7**. Please update code that references `federal_cty_unharm$ags` or `federal_cty_unharm$year` to use `county_code` and `election_year` instead. A one-time message is printed on each load.

## Bug Fixes

* `load_gerda_web()` now downloads datasets to a tempfile before reading them. This fixes loading of xz-compressed RDS files (e.g. `ags_1990_to_2025_crosswalk`), which `readr::read_rds()` could not stream from a URL.
* Download timeout is temporarily raised to 300s inside `load_gerda_web()` so the larger GERDA files (`mayor_panel_annual_harm`, `federal_muni_harm_21`) no longer time out on first pull over slower connections. The user's original timeout is restored on exit.
* Fixed the `add_gerda_covariates()` help example, which grouped on a non-existent `county_code_21` column after merging covariates into municipal data.

## Usability

* `load_gerda_web()` gains an `on_error` argument (`"warn"` default, `"stop"` for pipelines). Set `options(gerda.on_error = "stop")` to flip the default globally. Previous behaviour (warning + `NULL`) is unchanged.
* `party_crosswalk()` now lists all 21 available destinations in the help page and in its error message. A typo like `party_crosswalk(..., "family_nme")` now tells you exactly which column names are valid.
* `gerda_data_list(print_table = TRUE)` prints each row on a single uncut line. Dataset pairs like `federal_muni_harm_21` and `federal_muni_harm_25` are now distinguishable by description in narrow terminals.
* `load_gerda_web()` help now documents that major-party vote-share columns do not sum to 1: the remainder is held by smaller-party columns and the `other` bucket.
* Vignette gains a "Joining GERDA datasets" section listing the id and time columns for every dataset family, so manual `left_join()` calls don't trip on `year` vs `election_year` or on the municipal `county` column not being a 5-digit AGS code.

## Docs

* `DESCRIPTION` updated to list all six election families and the correct federal coverage window (federal county-level since 1953).
* `README.md` install section documents `build_vignettes = TRUE` for development installs from GitHub.
* `knitr` moved from Imports to Suggests (only needed as VignetteBuilder).

## Tests

* Test suite reorganized: `tests/testthat/test-load_gerda_web.R` split into five focused files (`-validation`, `-fuzzy`, `-extensions`, `-catalog`, `-schema`) to keep concerns separable as the catalog grows.
* Catalog coverage extended to all 39 exposed datasets, grouped by family.
* Added regression tests for the xz RDS load, the `federal_cty_unharm` alias + deprecation message, and the new `on_error` argument. Suite grew from 240 to 300 tests.

# gerda 0.4.0

## Bug Fixes and Improvements

* Improved error messages for deprecated `federal_muni_harm` dataset with clear migration guidance
* Enhanced fuzzy matching to prioritize prefix matches (e.g., `federal_muni_harm` now correctly suggests `federal_muni_harm_21` and `federal_muni_harm_25`)
* Added references to `gerda_data_list()` in all error messages to help users discover available datasets
* Updated README and vignette to reflect current data coverage (1990-2025)
* Fixed function references in documentation (`gerda_covariates` and `gerda_covariates_codebook`)

# gerda 0.3.0

## New Features

* Added county-level covariates functionality: Easy access to socioeconomic and demographic indicators (1995-2022)
  * New function: `add_gerda_covariates()` - One-step helper to merge covariates with election data
  * New function: `gerda_covariates()` - Access raw covariate data (400 counties, 20 variables)
  * New function: `gerda_covariates_codebook()` - View data dictionary with variable descriptions
  * Works with both county-level and municipal-level election data
  * 400 German counties with covariates from INKAR
  * Includes demographics, economy, labor market, education, and income variables
  * Data source: Bundesinstitut für Bau-, Stadt- und Raumforschung (BBSR)
  * Function-based API prevents namespace pollution and merge errors

## Other Changes

* Updated R dependency to >= 3.5.0 (required for internal data serialization)

# gerda 0.2.1

## Bug Fixes and Improvements

* Improved error message clarity for file extensions
* Changed message from "Format ignored" to "File extension (.rds or .csv) not required - adding it is optional"
* Simplified user messages by removing redundant information about data format independence
* Updated tests to match improved message format

# gerda 0.2.0

## New Features

* Added support for 2025 German federal election data
* New datasets available:
  * `federal_muni_harm_21`: Federal elections harmonized to 2021 boundaries (1990-2025)
  * `federal_muni_harm_25`: Federal elections harmonized to 2025 boundaries (1990-2025)

## Breaking Changes

* Removed `federal_muni_harm` dataset (replaced by boundary-specific versions)
* Users should now use `federal_muni_harm_21` or `federal_muni_harm_25` depending on their boundary harmonization needs

## Improvements

* Updated data coverage to include 2025 federal election results
* Improved dataset descriptions to clarify boundary harmonization
* Enhanced error messages with helpful suggestions for deprecated dataset names

## Bug Fixes

* Updated all URLs to reflect new repository structure
* Fixed dataset count in documentation and tests

# gerda 0.1.0

* Initial CRAN submission
* Access to German election data from 1990-2021
* Support for municipal, state, and federal election data
* Geographically harmonized datasets
* Cross-walk tables for boundary changes
