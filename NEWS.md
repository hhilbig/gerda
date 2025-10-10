# gerda (development version)

## New Features

* Added `county_covariates` dataset: County-level socioeconomic and demographic indicators (1995-2022)
  * 400 German counties with 20 covariates from INKAR
  * Designed for easy merging with GERDA election data
  * Includes demographics, economy, labor market, education, and income variables
  * Data source: Bundesinstitut für Bau-, Stadt- und Raumforschung (BBSR)

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
