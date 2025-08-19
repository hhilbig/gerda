test_that("gerda_data_list returns correct structure with print_table = TRUE", {
    # Capture output to test both printed table and returned data
    output <- capture.output(result <- gerda_data_list(print_table = TRUE))

    # Test that result is a tibble
    expect_s3_class(result, "tbl_df")
    expect_s3_class(result, "data.frame")

    # Test that result has expected columns
    expect_true(all(c("data_name", "description") %in% colnames(result)))

    # Test that result has expected number of rows (14 datasets as of current version)
    expect_equal(nrow(result), 14)

    # Test that output was captured (meaning something was printed)
    expect_gt(length(output), 0)

    # Test that specific datasets are present
    expected_datasets <- c(
        "municipal_unharm", "municipal_harm", "state_unharm",
        "state_harm", "federal_muni_raw", "federal_muni_unharm",
        "federal_muni_harm_21", "federal_muni_harm_25",
        "federal_cty_unharm", "federal_cty_harm",
        "ags_crosswalks", "cty_crosswalks", "ags_area_pop_emp",
        "cty_area_pop_emp"
    )
    expect_true(all(expected_datasets %in% result$data_name))
})

test_that("gerda_data_list returns correct structure with print_table = FALSE", {
    result <- gerda_data_list(print_table = FALSE)

    # Test that result is a tibble
    expect_s3_class(result, "tbl_df")
    expect_s3_class(result, "data.frame")

    # Test that result has expected columns
    expect_true(all(c("data_name", "description") %in% colnames(result)))

    # Test that result has expected number of rows
    expect_equal(nrow(result), 14)

    # Test that no output is printed when print_table = FALSE
    output <- capture.output(result2 <- gerda_data_list(print_table = FALSE))
    expect_equal(length(output), 0)
})

test_that("gerda_data_list data integrity", {
    result <- gerda_data_list(print_table = FALSE)

    # Test that all data_name entries are non-empty strings
    expect_true(all(nchar(result$data_name) > 0))
    expect_true(all(is.character(result$data_name)))

    # Test that all description entries are non-empty strings
    expect_true(all(nchar(result$description) > 0))
    expect_true(all(is.character(result$description)))

    # Test that data_name entries are unique
    expect_equal(length(result$data_name), length(unique(result$data_name)))

    # Test specific descriptions contain expected content
    expect_true(any(grepl("Local elections", result$description)))
    expect_true(any(grepl("State elections", result$description)))
    expect_true(any(grepl("Federal elections", result$description)))
    expect_true(any(grepl("harmonized", result$description)))
    expect_true(any(grepl("unharmonized", result$description)))
})

test_that("gerda_data_list default parameter behavior", {
    # Test that default behavior (no parameters) works like print_table = TRUE
    output1 <- capture.output(result1 <- gerda_data_list())
    output2 <- capture.output(result2 <- gerda_data_list(print_table = TRUE))

    expect_equal(result1, result2)
    expect_gt(length(output1), 0)
    expect_gt(length(output2), 0)
})
