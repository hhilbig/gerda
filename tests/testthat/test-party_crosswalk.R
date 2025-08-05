test_that("party_crosswalk basic functionality works", {
    # Test basic party mapping with known parties
    result <- party_crosswalk(c("cdu", "spd", "grune"), "party_name_english")

    expect_equal(length(result), 3)
    expect_true(is.character(result))
    expect_true("Christian Democratic Union" %in% result)
    expect_true("Social Democratic Party of Germany" %in% result)
    expect_true("Alliance 90 / Greens" %in% result)
})

test_that("party_crosswalk handles numeric destinations", {
    # Test with numeric destination (left_right scores)
    result <- party_crosswalk(c("cdu", "spd"), "left_right")

    expect_equal(length(result), 2)
    expect_true(is.numeric(result))
    expect_true(all(!is.na(result)))

    # CDU should be more right-wing than SPD
    cdu_score <- party_crosswalk("cdu", "left_right")
    spd_score <- party_crosswalk("spd", "left_right")
    expect_gt(cdu_score, spd_score)
})

test_that("party_crosswalk handles NA values correctly", {
    # Test that NA input produces appropriate NA output
    result_char <- party_crosswalk(c("cdu", NA, "spd"), "party_name_english")
    expect_equal(length(result_char), 3)
    expect_true(is.na(result_char[2]))
    expect_true(is.character(result_char[2]))

    result_num <- party_crosswalk(c("cdu", NA, "spd"), "left_right")
    expect_equal(length(result_num), 3)
    expect_true(is.na(result_num[2]))
    expect_true(is.numeric(result_num[2]))
})

test_that("party_crosswalk handles unknown parties", {
    # Test that unknown parties return NA
    result <- party_crosswalk(c("cdu", "unknown_party", "spd"), "party_name_english")

    expect_equal(length(result), 3)
    expect_false(is.na(result[1])) # cdu should be found
    expect_true(is.na(result[2])) # unknown_party should be NA
    expect_false(is.na(result[3])) # spd should be found
})

test_that("party_crosswalk validates destination parameter", {
    # Test invalid destination column
    expect_error(
        party_crosswalk(c("cdu", "spd"), "nonexistent_column"),
        "destination must be a column of the view_party table"
    )

    # Test multiple destination values
    expect_error(
        party_crosswalk(c("cdu", "spd"), c("left_right", "party_name")),
        "destination must be single character string"
    )
})

test_that("party_crosswalk validates party_gerda parameter", {
    # Test non-character input
    expect_error(
        party_crosswalk(c(1, 2, 3), "left_right"),
        "party_gerda must be a character vector"
    )

    expect_error(
        party_crosswalk(123, "left_right"),
        "party_gerda must be a character vector"
    )

    expect_error(
        party_crosswalk(TRUE, "left_right"),
        "party_gerda must be a character vector"
    )
})

test_that("party_crosswalk preserves vector length", {
    # Test that output length always matches input length
    inputs <- list(
        character(0), # empty vector
        "cdu", # single element
        c("cdu", "spd"), # two elements
        c("cdu", "spd", "grune", "fdp", "linke_pds"), # multiple elements
        c("cdu", NA, "unknown", "spd") # mixed valid/invalid/NA
    )

    for (input in inputs) {
        result <- party_crosswalk(input, "party_name_english")
        expect_equal(length(result), length(input))
    }
})

test_that("party_crosswalk works with different destination columns", {
    # Test various destination columns that should exist
    test_party <- "cdu"

    destinations_char <- c(
        "party_name_ascii", "party_name_short",
        "party_name_english", "family_name_short", "family_name"
    )
    destinations_num <- c(
        "left_right", "state_market", "liberty_authority",
        "eu_anti_pro", "country_id", "party_id"
    )

    # Test character destinations
    for (dest in destinations_char) {
        result <- party_crosswalk(test_party, dest)
        expect_true(is.character(result))
        expect_equal(length(result), 1)
    }

    # Test numeric destinations
    for (dest in destinations_num) {
        result <- party_crosswalk(test_party, dest)
        expect_true(is.numeric(result))
        expect_equal(length(result), 1)
    }
})

test_that("party_crosswalk edge cases", {
    # Test empty character vector
    result <- party_crosswalk(character(0), "party_name_english")
    expect_equal(length(result), 0)
    expect_true(is.character(result))

    # Test vector of all NAs (convert to character to avoid type issues)
    result <- party_crosswalk(as.character(c(NA, NA, NA)), "left_right")
    expect_equal(length(result), 3)
    expect_true(all(is.na(result)))
    expect_true(is.numeric(result))

    # Test vector of all unknown parties
    result <- party_crosswalk(c("unknown1", "unknown2"), "party_name_english")
    expect_equal(length(result), 2)
    expect_true(all(is.na(result)))
    expect_true(is.character(result))
})

test_that("party_crosswalk specific party mappings", {
    # Test specific known party mappings to ensure data integrity
    expect_equal(party_crosswalk("cdu", "party_name_short"), "CDU")
    expect_equal(party_crosswalk("spd", "party_name_short"), "SPD")
    expect_equal(party_crosswalk("csu", "party_name_short"), "CSU")

    # Test that major parties have left-right scores
    major_parties <- c("cdu", "csu", "spd", "grune", "fdp", "linke_pds")
    lr_scores <- party_crosswalk(major_parties, "left_right")
    expect_true(all(!is.na(lr_scores)))
    expect_true(all(lr_scores >= 0 & lr_scores <= 10)) # Typical left-right scale
})
