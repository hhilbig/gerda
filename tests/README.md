# GERDA Package Test Suite

The package uses testthat edition 3. The suite is split by public function and download concern:

- `test-gerda_catalog.R`: internal catalog integrity and structured metadata.
- `test-gerda_data_list.R`: printed and machine-readable catalog behavior.
- `test-load_gerda_web-validation.R`: argument and error-mode validation.
- `test-load_gerda_web-fuzzy.R`: suggestions and deprecated dataset guidance.
- `test-load_gerda_web-extensions.R`: optional file extensions and formats.
- `test-load_gerda_web-download.R`: retry, Git LFS, and cache helpers.
- `test-load_gerda_web-catalog.R`: catalog-to-upstream download coverage.
- `test-load_gerda_web-schema.R`: known upstream schema normalization.
- `test-gerda_covariates.R`: bundled INKAR data and joins.
- `test-gerda_census.R`: bundled Census 2022 data and joins.
- `test-gerda_join.R`: identifier validation, many-to-one guarantees, unmatched modes, coverage classification, and diagnostics.
- `test-party_crosswalk.R`: ParlGov mappings and validation.
- `test-integration.R`: representative cross-function workflows.

## Running the Tests

To run the complete test suite:

```r
# Install and load required packages
library(devtools)

# Run all tests
test()

# Or run a specific test file
test_file("tests/testthat/test-load_gerda_web-validation.R")
```

Tests that download data from GitHub use `skip_on_cran()`. They are skipped during CRAN checks and other runs where `NOT_CRAN` is not `"true"`. Offline tests still cover validation, catalog integrity, bundled data, cache logic, fuzzy matching, and merge behavior.

## Test Philosophy

These tests are designed to:

1. Validate public behavior and error contracts.
2. Prevent catalog, schema, and bundled-data regressions.
3. Document expected behavior through executable examples.
4. Separate deterministic offline checks from network-dependent integration checks.

## Dependencies

The tests require the following packages:

- `testthat` (>= 3.0.0) - Testing framework
- `dplyr` - Package dependency and integration workflows

Optional dependencies:

- `devtools` - For running tests during development
