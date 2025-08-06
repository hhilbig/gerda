test_that("load_gerda_web handles invalid file names correctly", {
    # Test completely invalid file name
    expect_warning(result <- load_gerda_web("invalid_dataset_name"))
    expect_null(result)

    # Test that warning message is informative
    expect_warning(
        load_gerda_web("nonexistent"),
        "File name not found in data dictionary"
    )
})

test_that("load_gerda_web fuzzy matching works", {
    # Test close matches provide helpful suggestions
    expect_warning(
        result <- load_gerda_web("municipal_harn"), # Missing 'm' from 'harm'
        "Did you mean"
    )
    expect_null(result)

    expect_warning(
        result <- load_gerda_web("federal_muni"), # Partial match
        "Did you mean"
    )
    expect_null(result)

    expect_warning(
        result <- load_gerda_web("state_unhar"), # Close to 'state_unharm'
        "Did you mean"
    )
    expect_null(result)
})

test_that("load_gerda_web validates file_format parameter", {
    # Test invalid file format
    expect_warning(
        result <- load_gerda_web("municipal_harm", file_format = "xlsx"),
        "Invalid file_format. Must be either 'csv' or 'rds'"
    )
    expect_null(result)

    expect_warning(
        result <- load_gerda_web("municipal_harm", file_format = "json"),
        "Invalid file_format"
    )
    expect_null(result)
})

test_that("load_gerda_web accepts valid dataset names", {
    # Test that valid dataset names are recognized (without actually downloading)
    valid_datasets <- c(
        "municipal_unharm", "municipal_harm", "state_unharm",
        "state_harm", "federal_muni_raw", "federal_muni_unharm",
        "federal_muni_harm_21", "federal_muni_harm_25",
        "federal_cty_unharm", "federal_cty_harm",
        "ags_crosswalks", "cty_crosswalks", "ags_area_pop_emp",
        "cty_area_pop_emp"
    )

    for (dataset in valid_datasets) {
        # We don't actually want to download during testing, but we can check
        # that the function gets past the validation stage
        # Note: In a production environment, you might want to mock the HTTP requests
        expect_silent({
            # This will likely fail at the download stage, but shouldn't give
            # validation warnings
            suppressWarnings(load_gerda_web(dataset, verbose = FALSE))
        })
    }
})

test_that("load_gerda_web verbose parameter works", {
    # Test verbose = FALSE (default)
    output_false <- capture.output({
        suppressWarnings(result <- load_gerda_web("municipal_harm", verbose = FALSE))
    })

    # With verbose = FALSE, no messages should be printed (only warnings if download fails)
    # We'll suppress warnings to focus on messages
    expect_silent({
        suppressWarnings(load_gerda_web("municipal_harm", verbose = FALSE))
    })
})

test_that("load_gerda_web handles both csv and rds formats", {
    # Test that both formats are accepted without validation errors
    # Note: We suppress both warnings and messages since downloading may produce messages
    expect_silent({
        suppressWarnings(suppressMessages(load_gerda_web("municipal_harm", file_format = "csv", verbose = FALSE)))
    })

    expect_silent({
        suppressWarnings(suppressMessages(load_gerda_web("municipal_harm", file_format = "rds", verbose = FALSE)))
    })
})

test_that("load_gerda_web parameter validation", {
    # Test that function handles edge cases in parameters
    expect_error(
        load_gerda_web("", file_format = "rds")
    )

    expect_error(
        load_gerda_web(NULL, file_format = "rds")
    )

    # Test default file_format
    expect_silent({
        suppressWarnings(load_gerda_web("municipal_harm")) # Should default to "rds"
    })
})

# Note: For comprehensive testing in a production environment, you would want to:
# 1. Mock HTTP requests to test successful data loading
# 2. Test actual data structure and content when files are successfully loaded
# 3. Test network error handling
# The current tests focus on parameter validation and error handling that
# can be tested without network dependencies.
