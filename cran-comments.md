# cran-comments.md — gerda 0.6.0

## Purpose of this release

This is a feature + bug-fix release over 0.5.0. The main changes are:

- Exposes 25 additional datasets via `load_gerda_web()` and `gerda_data_list()`, growing the catalog from 14 to 39. New families: county (Kreistag) elections, European Parliament elections, mayoral elections (results, candidates, and person- and municipality-level panels), boundary-specific harmonizations for state and municipal elections, additional AGS crosswalks, and 2023-boundary municipal covariates.
- Fixes a bug where xz-compressed RDS datasets could not be loaded (regression on `ags_1990_to_2025_crosswalk`).
- Adds a deprecation-alias for `federal_cty_unharm`: the file now exposes both the upstream `ags`/`year` columns and the canonical `county_code`/`election_year` names so it can be piped into `add_gerda_covariates()`. The `ags`/`year` aliases are scheduled for removal in v0.7.
- New `on_error` argument to `load_gerda_web()` lets users promote warnings to errors (useful in scripts and pipelines); default behaviour is unchanged.
- Several documentation improvements (joining-datasets reference in the vignette, clearer `party_crosswalk` destinations, non-truncated `gerda_data_list` printing).

See `NEWS.md` for the full list.

## Test environments

- Local: macOS 15.1 (arm64), R 4.5.x — `R CMD check --as-cran`: 0 errors, 0 warnings, 0 notes.
- win-builder (R-devel): tarball uploaded via <https://win-builder.r-project.org/upload.aspx> (the automated `devtools::check_win_devel()` FTP upload was blocked by the submitter's local network). Results will be appended here before the formal CRAN submission.

## R CMD check results

0 errors | 0 warnings | 0 notes.

## Network-dependent tests and examples

Tests that exercise `load_gerda_web()` actually download datasets from GitHub (<https://github.com/awiedem/german_election_data>). These tests are guarded with `skip_on_cran()` so CRAN check farms do not hit the network. Pure parameter-validation, fuzzy-matching, and party-crosswalk tests still run on CRAN.

Examples that call `load_gerda_web()` are wrapped in `\donttest{}` or `\dontrun{}` for the same reason.

## Reverse dependencies

No reverse dependencies on CRAN. Confirmed on 2026-04-19:

```r
tools::package_dependencies("gerda", reverse = TRUE,
                            db = available.packages())$gerda
#> character(0)
```

## Contact

Maintainer: Hanno Hilbig <hhilbig@ucdavis.edu>
