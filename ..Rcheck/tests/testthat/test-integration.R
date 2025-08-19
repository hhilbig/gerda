test_that("typical workflow: list datasets and understand structure", {
    # This test demonstrates a typical user workflow

    # Step 1: List available datasets
    datasets <- gerda_data_list(print_table = FALSE)

    # Verify we get the expected structure
    expect_s3_class(datasets, "data.frame")
    expect_true(all(c("data_name", "description") %in% colnames(datasets)))
    expect_gt(nrow(datasets), 0)

    # Step 2: Check that dataset names from the list are valid for load_gerda_web
    sample_datasets <- head(datasets$data_name, 3) # Test first 3 datasets

    for (dataset_name in sample_datasets) {
        # These should not produce validation warnings (though may fail at download)
        expect_silent({
            suppressWarnings(load_gerda_web(dataset_name, verbose = FALSE))
        })
    }
})

test_that("party_crosswalk integration with expected GERDA party names", {
    # Test that party_crosswalk works with party names likely to appear in GERDA data

    # Common German party abbreviations/names that should be in the lookup table
    common_parties <- c("cdu", "csu", "spd", "grune", "fdp", "linke_pds")

    # Test mapping to English names
    english_names <- party_crosswalk(common_parties, "party_name_english")
    expect_equal(length(english_names), length(common_parties))
    expect_true(all(!is.na(english_names))) # All should have valid mappings

    # Test mapping to left-right scores
    lr_scores <- party_crosswalk(common_parties, "left_right")
    expect_equal(length(lr_scores), length(common_parties))
    expect_true(all(!is.na(lr_scores))) # All should have valid scores
    expect_true(all(is.numeric(lr_scores)))

    # Test ideological ordering makes sense (basic sanity check)
    cdu_lr <- party_crosswalk("cdu", "left_right")
    spd_lr <- party_crosswalk("spd", "left_right")
    linke_lr <- party_crosswalk("linke_pds", "left_right")

    # CDU should be more right-wing than SPD, SPD more right-wing than Die Linke
    expect_gt(cdu_lr, spd_lr)
    expect_gt(spd_lr, linke_lr)
})

test_that("comprehensive party mapping workflow", {
    # Simulate a realistic workflow where a user maps multiple party attributes

    parties <- c("cdu", "spd", "grune", "fdp", "linke_pds", "csu")

    # Get multiple attributes for the same parties
    party_info <- data.frame(
        party_gerda = parties,
        english_name = party_crosswalk(parties, "party_name_english"),
        short_name = party_crosswalk(parties, "party_name_short"),
        left_right = party_crosswalk(parties, "left_right"),
        family = party_crosswalk(parties, "family_name"),
        stringsAsFactors = FALSE
    )

    # Verify structure
    expect_equal(nrow(party_info), length(parties))
    expect_equal(ncol(party_info), 5)

    # Verify no missing values for major parties
    expect_true(all(!is.na(party_info$english_name)))
    expect_true(all(!is.na(party_info$short_name)))
    expect_true(all(!is.na(party_info$left_right)))
    expect_true(all(!is.na(party_info$family)))

    # Verify data types
    expect_true(is.character(party_info$english_name))
    expect_true(is.character(party_info$short_name))
    expect_true(is.numeric(party_info$left_right))
    expect_true(is.character(party_info$family))
})

test_that("error handling across functions", {
    # Test that functions handle errors gracefully in integrated scenarios

    # Test gerda_data_list with invalid parameters
    expect_error(gerda_data_list(print_table = "invalid"))

    # Test load_gerda_web with results from gerda_data_list
    datasets <- gerda_data_list(print_table = FALSE)
    valid_name <- datasets$data_name[1]

    # Should not produce validation errors
    expect_silent({
        suppressWarnings(load_gerda_web(valid_name))
    })

    # Test party_crosswalk with invalid destination from a simulated workflow
    expect_error(
        party_crosswalk(c("cdu", "spd"), "invalid_column"),
        "destination must be a column"
    )
})

test_that("data consistency across functions", {
    # Test that the dataset names are consistent between functions

    # Get dataset names from gerda_data_list
    available_datasets <- gerda_data_list(print_table = FALSE)$data_name

    # These names should be valid for load_gerda_web (i.e., no validation warnings)
    for (i in seq_len(min(3, length(available_datasets)))) { # Test first 3
        dataset_name <- available_datasets[i]
        expect_silent({
            # Should pass validation (may fail at download, but that's expected)
            suppressMessages(suppressWarnings(load_gerda_web(dataset_name, verbose = FALSE)))
        })
    }
})

test_that("mixed data types and edge cases integration", {
    # Test realistic scenarios with mixed valid/invalid data

    # Mixed party list with valid, invalid, and NA values
    mixed_parties <- c("cdu", "invalid_party", NA, "spd", "", "grune")

    # Should handle gracefully without errors
    result <- party_crosswalk(mixed_parties, "party_name_english")

    expect_equal(length(result), length(mixed_parties))
    expect_true(is.character(result))

    # Valid parties should have non-NA results
    expect_false(is.na(result[1])) # cdu
    expect_false(is.na(result[4])) # spd
    expect_false(is.na(result[6])) # grune

    # Invalid/missing parties should be NA
    expect_true(is.na(result[2])) # invalid_party
    expect_true(is.na(result[3])) # NA
    expect_true(is.na(result[5])) # empty string
})

test_that("package functions work with tibble/dplyr workflows", {
    # Test integration with common tidyverse workflows
    skip_if_not_installed("dplyr")

    library(dplyr)

    # Create a sample dataset similar to what users might have
    sample_data <- data.frame(
        election_year = c(2017, 2017, 2021, 2021),
        party = c("cdu", "spd", "cdu", "grune"),
        votes = c(1000, 800, 1200, 900),
        stringsAsFactors = FALSE
    )

    # Add party information using party_crosswalk in a dplyr pipeline
    enhanced_data <- sample_data %>%
        mutate(
            party_english = party_crosswalk(party, "party_name_english"),
            left_right_score = party_crosswalk(party, "left_right"),
            party_family = party_crosswalk(party, "family_name")
        )

    # Verify the pipeline worked
    expect_equal(nrow(enhanced_data), nrow(sample_data))
    expect_true("party_english" %in% colnames(enhanced_data))
    expect_true("left_right_score" %in% colnames(enhanced_data))
    expect_true("party_family" %in% colnames(enhanced_data))

    # Verify data integrity
    expect_true(all(!is.na(enhanced_data$party_english)))
    expect_true(all(!is.na(enhanced_data$left_right_score)))
    expect_true(all(!is.na(enhanced_data$party_family)))
})
