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

test_that("on_error = 'stop' converts warnings into errors", {
    # Unknown dataset name: default "warn" yields NULL + warning.
    expect_warning(
        res <- load_gerda_web("this_dataset_does_not_exist"),
        "File name not found"
    )
    expect_null(res)

    # With on_error = "stop", the same input throws.
    expect_error(
        load_gerda_web("this_dataset_does_not_exist", on_error = "stop"),
        "File name not found"
    )

    # Invalid file_format: same promotion behaviour.
    expect_warning(
        res <- load_gerda_web("municipal_harm", file_format = "xlsx"),
        "Invalid file_format"
    )
    expect_null(res)
    expect_error(
        load_gerda_web("municipal_harm", file_format = "xlsx", on_error = "stop"),
        "Invalid file_format"
    )

    # Deprecated federal_muni_harm: warn path returns NULL; stop path errors.
    expect_warning(
        res <- load_gerda_web("federal_muni_harm"),
        "replaced with two boundary-specific versions"
    )
    expect_null(res)
    expect_error(
        load_gerda_web("federal_muni_harm", on_error = "stop"),
        "replaced with two boundary-specific versions"
    )
})

test_that("on_error argument is validated", {
    expect_error(
        load_gerda_web("municipal_harm", on_error = "explode"),
        "on_error must be either"
    )
    expect_error(
        load_gerda_web("municipal_harm", on_error = c("warn", "stop")),
        "on_error must be either"
    )
})

test_that("options(gerda.on_error = 'stop') flips the default", {
    old <- getOption("gerda.on_error")
    on.exit(options(gerda.on_error = old), add = TRUE)
    options(gerda.on_error = "stop")
    expect_error(
        load_gerda_web("this_dataset_does_not_exist"),
        "File name not found"
    )
})
