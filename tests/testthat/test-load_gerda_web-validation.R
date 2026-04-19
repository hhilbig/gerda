test_that("load_gerda_web handles invalid file names correctly", {
    expect_warning(result <- load_gerda_web("invalid_dataset_name"))
    expect_null(result)

    expect_warning(
        load_gerda_web("nonexistent"),
        "File name not found in data dictionary"
    )
    expect_warning(
        load_gerda_web("nonexistent"),
        "gerda_data_list"
    )
})

test_that("load_gerda_web validates file_format parameter", {
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

test_that("load_gerda_web parameter validation", {
    expect_error(
        load_gerda_web("", file_format = "rds")
    )

    expect_error(
        load_gerda_web(NULL, file_format = "rds")
    )

    # Default file_format
    expect_silent({
        suppressWarnings(load_gerda_web("municipal_harm"))
    })
})

test_that("load_gerda_web verbose parameter works", {
    expect_silent({
        suppressWarnings(load_gerda_web("municipal_harm", verbose = FALSE))
    })
})

test_that("load_gerda_web handles both csv and rds formats", {
    expect_silent({
        suppressWarnings(suppressMessages(
            load_gerda_web("municipal_harm", file_format = "csv", verbose = FALSE)
        ))
    })

    expect_silent({
        suppressWarnings(suppressMessages(
            load_gerda_web("municipal_harm", file_format = "rds", verbose = FALSE)
        ))
    })
})
