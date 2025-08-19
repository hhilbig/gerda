# GERDA Package Test Suite

This directory contains comprehensive tests for the GERDA package, written using the `testthat` framework.

## Test Structure

The test suite is organized into the following files:

### `test-gerda_data_list.R`

Tests for the `gerda_data_list()` function:

- Validates output structure with both `print_table = TRUE/FALSE`
- Tests data integrity and completeness
- Verifies default parameter behavior
- Ensures all expected datasets are present

### `test-load_gerda_web.R`

Tests for the `load_gerda_web()` function:

- Parameter validation (file names, formats)
- Error handling for invalid inputs
- Fuzzy matching functionality for similar dataset names
- Format validation (CSV vs RDS)
- Edge cases and boundary conditions

**Note**: These tests focus on parameter validation and error handling rather than actual data downloading, to avoid network dependencies during testing.

### `test-party_crosswalk.R`

Tests for the `party_crosswalk()` function:

- Basic functionality with known German parties
- Handling of different destination columns (character vs numeric)
- NA value processing
- Parameter validation and error handling
- Edge cases (empty vectors, unknown parties)
- Data type consistency

### `test-integration.R`

Integration tests demonstrating typical package workflows:

- Complete workflow from listing datasets to loading data
- Party crosswalk integration with common German parties
- Error handling across multiple functions
- Data consistency between functions
- Integration with tidyverse/dplyr workflows

## Running the Tests

To run the complete test suite:

```r
# Install and load required packages
library(devtools)

# Run all tests
test()

# Or run specific test files
test_file("tests/testthat/test-gerda_data_list.R")
```

## Test Coverage

The test suite includes **164 individual test cases** covering:

- ✅ All three main package functions
- ✅ Parameter validation and error handling
- ✅ Edge cases and boundary conditions
- ✅ Data integrity and consistency
- ✅ Integration workflows
- ✅ Compatibility with tidyverse tools

## Expected Test Results

When all tests pass, you should see output similar to:

```
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 164 ]
```

## Test Philosophy

These tests are designed to:

1. **Validate functionality** - Ensure all functions work as documented
2. **Prevent regressions** - Catch breaking changes during development  
3. **Document expected behavior** - Serve as executable specifications
4. **Handle edge cases** - Test boundary conditions and error scenarios
5. **Support CI/CD** - Enable automated testing in development workflows

## Dependencies

The tests require the following packages:

- `testthat` (>= 3.0.0) - Testing framework
- `dplyr` - For integration tests with tidyverse workflows

Optional dependencies:

- `devtools` - For running tests during development
