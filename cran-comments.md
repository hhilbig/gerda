## Test environments

* macOS 15.2 (aarch64), R 4.5.2

## R CMD check results

0 errors | 0 warnings | 2 NOTEs

* checking HTML version of manual ... NOTE
  Skipping checking math rendering: package 'V8' is not available
  (HTML Tidy version difference — cosmetic only)

* checking for non-standard things in the check directory ... NOTE
  Found the following files/directories:
    '.DS_Store'
  (macOS filesystem artifact — not included in package)

## Submission notes

This is an update from 0.4.0 to 0.5.0.

### New in this version

* Census 2022 module: 3 new exported functions (`gerda_census()`,
  `gerda_census_codebook()`, `add_gerda_census()`) providing municipality-level
  demographic data from the German Census 2022.
* Extended INKAR covariates: expanded from 20 to 30 county-level variables,
  adding healthcare, childcare, public finances, and transport categories.
* Added `stats` to Imports (used for `weighted.mean()`).
* Removed Strukturdaten module (functionality consolidated).
