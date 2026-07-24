# gerda 0.8.0

## New Data

* Added `county_council_seats` to the catalog (46 → 47 datasets): a yearly panel of county council (Kreistag) seat composition, 400 counties × 18 years (2008–2025), on a fixed set of current county boundaries. Seat vectors are carried forward between elections; reform-created counties are missing before they existed.
* `municipal_unharm` now includes ten council seat count columns (`seats_cdu_csu`, `seats_spd`, `seats_linke_pds`, `seats_gruene`, `seats_afd`, `seats_piraten`, `seats_fdp`, `seats_die_partei`, `seats_freie_wahler`, `seats_bsw`) where the state source reports them. Seats are deliberately absent from the harmonized municipal files: seat counts cannot be meaningfully summed across merged municipalities.
* Corrected stale catalog year ranges for the municipal family: `municipal_unharm` covers 1984–2026 and `municipal_harm` / `municipal_harm_25` cover 1990–2026 (previously listed as 1990–2020).

## Breaking Changes

* `load_gerda_web("federal_cty_unharm")` now renames the upstream `ags` and `year` columns to `county_code` and `election_year` on load and no longer keeps the deprecated duplicates. This completes the removal announced in 0.6.0 (and deferred once in 0.7.0); a one-time message on load points existing code to the new names.
* Corrected two misleading Census 2022 variable names to match the source bins: `share_50to64_census22` is now `share_50to59_census22`, and `share_65plus_census22` is now `share_60plus_census22`. Destatis publishes a combined age 60-74 bin, so true 50-64 and 65+ measures cannot be recovered from these tables.
* `add_gerda_covariates()` and `add_gerda_census()` now reject numeric or malformed geographic identifiers. County codes must be five-digit character strings and municipality AGS codes must be eight-digit character strings; this prevents joins after leading zeros have been lost. The helpers also reject destination-column conflicts instead of creating ambiguous suffixes.

## Safer Joins

* Added `unmatched = "warn"`, `"error"`, or `"ignore"` to both enrichment helpers. Exact unmatched row and unit counts are reported; INKAR election years outside 1995-2022 are classified separately and retained with missing joined values.
* Both helpers now verify that bundled reference keys are complete and unique before joining and that the output row count equals the input row count.
* Added `gerda_join_diagnostics()` to retrieve machine-readable reports for one or multiple enrichment joins.

## Documentation

* Updated the README and vignette for the 46-dataset catalog, including the state Wahlkreis and Landrat families.
* Added guidance for choosing raw, unharmonized, and harmonized datasets and documented the current join identifiers and time columns.
* Added an agent-oriented vignette covering deterministic catalog selection, fail-closed downloads, project snapshots and checksums, schema validation, guarded joins, and handoff requirements.
* Updated development and test-suite documentation to match the current package structure.

# gerda 0.7.1

## New Features

* Exposed four datasets that were already in the upstream repository but not in the catalog (43 → 46 datasets):
  * **State (Landtag) elections at the Wahlkreis (constituency) level**: `ltw_wkr_unharm` (vote shares) and `ltw_wkr_unharm_long` (vote counts), 1990–2026, all 16 states. The state-level counterpart to the federal `federal_wkr_*` datasets.
  * **Landrat (county executive) elections** — a new election family: `landrat_unharm` (county-level results) and `landrat_candidates` (person-level candidates, with Stichwahl and candidate attributes), 1945–2026. `gerda_data_list()` gains a corresponding `election_type` value, `landrat`.

## Bug Fixes

* Removed the catalog entry `county_elec_harm_21`, which pointed to a file that does not exist upstream (only `county_elec_harm_21_cty` and `county_elec_harm_21_muni` are published), so calling it always failed. `load_gerda_web("county_elec_harm_21")` now returns an "unknown dataset" message with fuzzy suggestions instead of a download error.

## Tests

* Hardened the catalog coverage test: it now asserts each dataset actually downloads to a non-empty data frame, rather than only that the call is silent. A lenient check previously let a broken/orphaned entry (like `county_elec_harm_21`) pass unnoticed.

# gerda 0.7.0

## New Features

* Exposed federal elections at the **Wahlkreis (constituency) level** — a new geographic level covering all 299 Bundestag constituencies for 2002-2025:
  * `federal_wkr_unharm` — vote shares per Wahlkreis x election x vote (Erst/Zweitstimme), GERDA-style wide format.
  * `federal_wkr_unharm_long` — the count-level long version.
  * `federal_wkr_2021_on_2025` — the official recomputation of the 2021 result onto the 2025 Wahlkreis boundaries (previous-election district strength on current boundaries).
  * `wkr_2021_to_2025_crosswalk` — the 2021->2025 constituency crosswalk with `unchanged` / `redrawn` / `new` categories.
* `load_gerda_web()` gains four arguments for more robust downloads (all with `getOption()` defaults so they can be set globally):
  * `timeout` (default `getOption("gerda.timeout", 300)`) makes the previously hard-coded download timeout configurable.
  * `max_retries` (default `getOption("gerda.max_retries", 2)`) retries failed downloads with exponential backoff, so up to three attempts are made before giving up.
  * `cache` (default `getOption("gerda.cache", FALSE)`) caches downloaded datasets on disk and reuses them on later calls instead of re-downloading. This is opt-in so the package never writes to user filespace without consent. Reusing a cached ~4 MB file is roughly 85x faster than re-downloading it, and the saving is far larger for the multi-hundred-MB harmonized panels.
  * `refresh` (default `FALSE`) forces a fresh download, updating the cache.
* New exported helpers `gerda_cache_dir()` and `clear_gerda_cache()` inspect and purge the download cache (location follows `tools::R_user_dir()` and honours `R_USER_CACHE_DIR`).
* GERDA data is served through Git LFS. `load_gerda_web()` now detects when a download returns a Git LFS pointer file instead of the real data (e.g. after a failed media redirect) and returns an informative, retryable error instead of a cryptic parse failure.
* `gerda_data_list(print_table = FALSE)` now returns structured metadata columns in addition to `data_name` and `description`: `election_type`, `geographic_level`, `year_start`, `year_end`, `boundary`, `formats`, and `candidate_info`. The printed table is unchanged.
* Requesting an unavailable format (e.g. `file_format = "csv"` for the RDS-only targeted crosswalks) now fails with a clear message naming the available format instead of hitting a 404.

## Internal

* The dataset catalog is now defined once in an internal `gerda_catalog()` function and consumed by both `load_gerda_web()` and `gerda_data_list()`, eliminating the previously hand-maintained duplicate lists that could drift.
* `DESCRIPTION` now declares `tools` and `utils` in Imports (used for `R_user_dir()` and `download.file()`).

## Deprecations

* The removal of the deprecated `federal_cty_unharm` `ags` and `year` columns, announced in 0.6.0 for v0.7, is deferred to **v0.8**. The `county_code`/`election_year` aliases remain the recommended columns; the originals are still available.

# gerda 0.6.0

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

# gerda 0.5.0

## New Features

* **Census 2022 module** -- 3 new exported functions for municipality-level demographic data:
  * `gerda_census()` -- access Census 2022 data (10,786 municipalities, 16 variables)
  * `gerda_census_codebook()` -- data dictionary for census variables
  * `add_gerda_census()` -- merge census data with election data (supports both municipality and county level)
* **Extended INKAR covariates** -- expanded from 20 to 30 variables, adding healthcare, childcare, public finances, and transport categories

## Other Changes

* Added `stats` to Imports (for `weighted.mean()` in county-level census aggregation)
* Removed Strukturdaten module (functionality consolidated into census and covariates modules)
* New tests for `gerda_covariates` and `gerda_census` modules
* Updated vignette and README with census and expanded covariates documentation

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
