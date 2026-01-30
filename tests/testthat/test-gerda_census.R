test_that("gerda_census returns a data frame with expected structure", {
  census <- gerda_census()

  expect_s3_class(census, "data.frame")
  expect_gt(nrow(census), 0)
  expect_true("ags" %in% names(census))
  expect_true("population" %in% names(census))
  expect_true("share_migration_bg" %in% names(census))
  expect_true("share_catholic" %in% names(census))
  expect_true("avg_household_size" %in% names(census))
  expect_true("vacancy_rate" %in% names(census))
  expect_true("share_university_deg" %in% names(census))
})

test_that("gerda_census_codebook returns a data frame with expected structure", {
  codebook <- gerda_census_codebook()

  expect_s3_class(codebook, "data.frame")
  expect_gt(nrow(codebook), 0)
  expect_true(all(c("variable", "label", "unit", "source") %in% names(codebook)))

  # All census data variables should be documented
  census <- gerda_census()
  census_vars <- names(census)
  documented_vars <- codebook$variable
  expect_true(all(census_vars %in% documented_vars))
})

test_that("add_gerda_census validates input", {
  expect_error(add_gerda_census("not a data frame"), "must be a data frame")

  # Missing required columns
  bad_data <- data.frame(x = 1:3)
  expect_error(add_gerda_census(bad_data), "must contain either")
})

test_that("add_gerda_census works with municipality-level data", {
  census <- gerda_census()
  sample_ags <- head(census$ags, 5)

  # Create mock municipal election data
  muni_data <- data.frame(
    ags = sample_ags,
    election_year = 2021,
    votes = c(100, 200, 150, 300, 250),
    stringsAsFactors = FALSE
  )

  result <- add_gerda_census(muni_data)

  # Should keep all original rows
  expect_equal(nrow(result), nrow(muni_data))

  # Should add census columns
  expect_true("population" %in% names(result))
  expect_true("share_migration_bg" %in% names(result))
  expect_true("vacancy_rate" %in% names(result))

  # Original columns should be preserved
  expect_true("votes" %in% names(result))
  expect_true("election_year" %in% names(result))
})

test_that("add_gerda_census works with county-level data", {
  census <- gerda_census()
  # Get some county codes from census AGS
  sample_counties <- unique(substr(census$ags, 1, 5))[1:3]

  county_data <- data.frame(
    county_code = sample_counties,
    election_year = 2021,
    votes = c(1000, 2000, 1500),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(add_gerda_census(county_data))

  # Should keep all original rows
  expect_equal(nrow(result), nrow(county_data))

  # Should add aggregated census columns (prefixed with census_)
  census_cols <- grep("^census_", names(result), value = TRUE)
  expect_gt(length(census_cols), 0)

  # Original columns should be preserved
  expect_true("votes" %in% names(result))
})

test_that("add_gerda_census prefers ags over county_code when both present", {
  census <- gerda_census()
  sample_ags <- head(census$ags, 3)

  both_data <- data.frame(
    ags = sample_ags,
    county_code = substr(sample_ags, 1, 5),
    election_year = 2021,
    stringsAsFactors = FALSE
  )

  # Should use ags and emit a message
  expect_message(add_gerda_census(both_data), "Using 'ags'")
})
