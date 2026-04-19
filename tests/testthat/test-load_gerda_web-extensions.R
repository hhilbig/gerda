test_that("load_gerda_web detects .rds / .csv extensions", {
    # Triggers a real fetch after stripping the extension; skip on CRAN.
    skip_on_cran()
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    # Extension does not need to match file_format arg
    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.rds", file_format = "csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    expect_message(
        suppressWarnings(result <- load_gerda_web("municipal_harm.csv", file_format = "rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )
})

test_that("load_gerda_web treats extensions as equivalent to bare name", {
    skip_on_cran()
    test_cases <- c(
        "municipal_harm",
        "municipal_harm.rds",
        "municipal_harm.csv"
    )

    for (test_case in test_cases) {
        expect_silent({
            suppressWarnings(suppressMessages(load_gerda_web(test_case, verbose = FALSE)))
        })
    }
})

test_that("load_gerda_web rejects names that merely contain '.rds'/'.csv'", {
    expect_warning(
        suppressMessages(result <- load_gerda_web("some_dataset_with_rds_in_name")),
        "File name not found in data dictionary"
    )
    expect_null(result)

    # Extension detection looks only at the last 4 characters
    expect_warning(
        suppressMessages(result <- load_gerda_web("municipal_harm.rds.backup")),
        "File name not found in data dictionary"
    )
    expect_null(result)
})

test_that("load_gerda_web extension message content is informative", {
    skip_on_cran()
    expect_message(
        suppressWarnings(load_gerda_web("municipal_harm.rds", file_format = "rds")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )

    expect_message(
        suppressWarnings(load_gerda_web("municipal_harm.csv", file_format = "csv")),
        "File extension \\(.rds or .csv\\) not required - adding it is optional"
    )
})
