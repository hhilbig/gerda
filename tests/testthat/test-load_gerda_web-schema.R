# Schema-normalization tests: the package is expected to rename columns on
# load for known upstream inconsistencies. These tests hit the network.

test_that("federal_cty_unharm exposes county_code/election_year as aliases while keeping ags/year", {
    skip_on_cran()
    data <- tryCatch(
        suppressWarnings(suppressMessages(
            load_gerda_web("federal_cty_unharm", file_format = "rds", verbose = FALSE)
        )),
        error = function(e) NULL
    )
    skip_if(is.null(data), "federal_cty_unharm could not be downloaded (network)")

    expect_s3_class(data, "data.frame")
    # New canonical names, added as aliases.
    expect_true("county_code" %in% names(data))
    expect_true("election_year" %in% names(data))
    # Original upstream names, kept for backwards compatibility (deprecated in v0.7).
    expect_true("ags" %in% names(data))
    expect_true("year" %in% names(data))

    # Alias values should equal the originals.
    expect_identical(data$county_code, data$ags)
    expect_identical(data$election_year, data$year)

    # county_code is a 5-character county AGS.
    sample_codes <- as.character(head(data$county_code, 100))
    code_lengths <- nchar(sample_codes[!is.na(sample_codes)])
    expect_true(all(code_lengths <= 5))
})

test_that("federal_cty_unharm emits a deprecation message on load", {
    skip_on_cran()
    # Capture messages to confirm the one-time deprecation notice fires.
    msgs <- tryCatch(
        capture.output(
            suppressWarnings(
                load_gerda_web("federal_cty_unharm", file_format = "rds", verbose = FALSE)
            ),
            type = "message"
        ),
        error = function(e) NULL
    )
    skip_if(is.null(msgs), "federal_cty_unharm could not be downloaded (network)")
    expect_true(any(grepl("deprecated", msgs, ignore.case = TRUE)))
    expect_true(any(grepl("v0\\.7", msgs)))
})

test_that("federal_cty_unharm can be piped into add_gerda_covariates", {
    skip_on_cran()
    data <- tryCatch(
        suppressWarnings(suppressMessages(
            load_gerda_web("federal_cty_unharm", file_format = "rds", verbose = FALSE)
        )),
        error = function(e) NULL
    )
    skip_if(is.null(data), "federal_cty_unharm could not be downloaded (network)")

    merged <- tryCatch(
        suppressWarnings(suppressMessages(add_gerda_covariates(data))),
        error = function(e) e
    )
    expect_s3_class(merged, "data.frame")
    expect_equal(nrow(merged), nrow(data))
    expect_true("county_code" %in% names(merged))
})

test_that("federal_cty_harm still uses county_code and election_year (no rename)", {
    skip_on_cran()
    data <- tryCatch(
        suppressWarnings(suppressMessages(
            load_gerda_web("federal_cty_harm", file_format = "rds", verbose = FALSE)
        )),
        error = function(e) NULL
    )
    skip_if(is.null(data), "federal_cty_harm could not be downloaded (network)")

    expect_true("county_code" %in% names(data))
    expect_true("election_year" %in% names(data))
})
