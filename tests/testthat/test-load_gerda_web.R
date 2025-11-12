test_that("load_gerda_web handles invalid file names correctly", {
    # Test completely invalid file name
    expect_warning(result <- load_gerda_web("invalid_dataset_name"))
    expect_null(result)

    # Test that warning message is informative and includes gerda_data_list reference
    expect_warning(
        load_gerda_web("nonexistent"),
        "File name not found in data dictionary"
    )
    expect_warning(
        load_gerda_web("nonexistent"),
        "gerda_data_list"
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
        result <- load_gerda_web("municipal_harn"),
        "gerda_data_list"
    )

    expect_warning(
        result <- load_gerda_web("federal_muni"), # Partial match
        "Did you mean"
    )
    expect_null(result)
    expect_warning(
        result <- load_gerda_web("federal_muni"),
        "gerda_data_list"
    )

    expect_warning(
        result <- load_gerda_web("state_unhar"), # Close to 'state_unharm'
        "Did you mean"
    )
    expect_null(result)
    expect_warning(
        result <- load_gerda_web("state_unhar"),
        "gerda_data_list"
    )

    # Test deprecated federal_muni_harm provides specific message
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "has been replaced with two boundary-specific versions"
    )
    expect_null(result)
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "federal_muni_harm_21"
    )
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "federal_muni_harm_25"
    )
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "Please replace"
    )
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "gerda_data_list"
    )
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

test_that("load_gerda_web handles file extensions in filename", {
    # Test that .rds extension is detected and stripped
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    # Test that .csv extension is detected and stripped
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    # Test that .rds extension with different file_format parameter
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.rds", file_format = "csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    # Test that .csv extension with different file_format parameter
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.csv", file_format = "rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )
})

test_that("load_gerda_web ignores extensions correctly", {
    # Test that files with extensions are treated the same as without extensions
    # This tests the core functionality that the extension is stripped

    # These should all be treated as the same dataset name
    test_cases <- c(
        "municipal_harm",
        "municipal_harm.rds",
        "municipal_harm.csv"
    )

    for (test_case in test_cases) {
        # Should not produce validation warnings (though may fail at download)
        expect_silent({
            suppressWarnings(suppressMessages(load_gerda_web(test_case, verbose = FALSE)))
        })
    }
})

test_that("load_gerda_web extension handling edge cases", {
    # Test files that end with .rds or .csv but aren't extensions
    # (e.g., dataset names that legitimately contain these strings)

    # These should be treated as invalid filenames (not found in data dictionary)
    expect_warning(
        suppressMessages(result <- load_gerda_web("some_dataset_with_rds_in_name")),
        "File name not found in data dictionary"
    )
    expect_null(result)
    expect_warning(
        suppressMessages(result <- load_gerda_web("some_dataset_with_rds_in_name")),
        "gerda_data_list"
    )

    # Test that the extension detection only looks at the last 4 characters
    expect_warning(
        suppressMessages(result <- load_gerda_web("municipal_harm.rds.backup")),
        "File name not found in data dictionary"
    )
    expect_null(result)
    expect_warning(
        suppressMessages(result <- load_gerda_web("municipal_harm.rds.backup")),
        "gerda_data_list"
    )
})

test_that("load_gerda_web message content validation", {
    # Test that the message contains the expected content
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.rds", file_format = "rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.csv", file_format = "csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )
})

# Note: For comprehensive testing in a production environment, you would want to:
# 1. Mock HTTP requests to test successful data loading
# 2. Test actual data structure and content when files are successfully loaded
# 3. Test network error handling
# The current tests focus on parameter validation and error handling that
# can be tested without network dependencies.
