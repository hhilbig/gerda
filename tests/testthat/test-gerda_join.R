test_that("GERDA joins reject unsafe identifiers and years", {
  expect_error(
    add_gerda_covariates(data.frame(
      county_code = 1001,
      election_year = 2020
    )),
    "Numeric identifiers can lose leading zeros"
  )
  expect_error(
    add_gerda_covariates(data.frame(
      county_code = "0100A",
      election_year = 2020
    )),
    "Invalid value\\(s\\): '0100A'"
  )
  expect_error(
    add_gerda_census(data.frame(ags = 1001000)),
    "Numeric identifiers can lose leading zeros"
  )
  expect_error(
    add_gerda_census(data.frame(ags = "0100100A")),
    "Invalid value\\(s\\): '0100100A'"
  )
  expect_error(
    add_gerda_covariates(data.frame(
      county_code = "01001",
      election_year = "2020"
    )),
    "numeric or integer year"
  )
  expect_error(
    add_gerda_covariates(data.frame(
      county_code = "01001",
      election_year = 2020.5
    )),
    "whole calendar years"
  )
  expect_error(
    add_gerda_census(data.frame(ags = "01001000"), unmatched = "drop"),
    'unmatched must be one of "warn", "error", or "ignore"'
  )
})

test_that("GERDA joins enforce a many-to-one, conflict-free contract", {
  duplicate_reference <- data.frame(id = c("a", "a"))
  missing_reference <- data.frame(id = c("a", NA_character_))

  expect_error(
    validate_gerda_join_key(duplicate_reference, "id", "Test reference"),
    "found 2 row\\(s\\) sharing duplicate keys"
  )
  expect_error(
    validate_gerda_join_key(missing_reference, "id", "Test reference"),
    "contains 1 row\\(s\\) with missing join keys"
  )
  expect_error(
    assert_gerda_row_count(2L, 3L, "test_join"),
    "changed the row count from 2 to 3"
  )

  covs <- gerda_covariates()
  covariate_input <- data.frame(
    county_code = covs$county_code[[1]],
    election_year = covs$year[[1]],
    unemployment_rate = 0
  )
  expect_error(
    add_gerda_covariates(covariate_input),
    "columns already present.*unemployment_rate"
  )

  census <- gerda_census()
  census_input <- data.frame(
    ags = census$ags[[1]],
    population_census22 = 0
  )
  expect_error(
    add_gerda_census(census_input),
    "columns already present.*population_census22"
  )
})

test_that("covariate joins report unexpected unmatched rows exactly", {
  covs <- gerda_covariates()
  year <- 2020
  real_county <- covs$county_code[covs$year == year][[1]]
  fake_county <- "99999"
  expect_false(fake_county %in% covs$county_code)

  input <- data.frame(
    county_code = c(real_county, fake_county, NA_character_),
    election_year = rep(year, 3),
    value = 1:3
  )

  result <- NULL
  expect_warning(
    result <- add_gerda_covariates(input),
    "2 of 3 eligible row\\(s\\) across 1 unit\\(s\\)"
  )
  diagnostics <- gerda_join_diagnostics(result)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(input))
  expect_equal(result$value, input$value)
  expect_equal(diagnostics$helper, "add_gerda_covariates")
  expect_equal(diagnostics$data_level, "county")
  expect_equal(diagnostics$input_rows, 3L)
  expect_equal(diagnostics$output_rows, 3L)
  expect_equal(diagnostics$eligible_rows, 3L)
  expect_equal(diagnostics$matched_rows, 1L)
  expect_equal(diagnostics$unmatched_rows, 2L)
  expect_equal(diagnostics$unexpected_unmatched_rows, 2L)
  expect_equal(diagnostics$missing_key_rows, 1L)
  expect_equal(diagnostics$matched_units, 1L)
  expect_equal(diagnostics$unmatched_units, 1L)
  expect_equal(diagnostics$unexpected_unmatched_units, 1L)
  expect_equal(diagnostics$eligible_match_rate, 1 / 3)
  expect_equal(
    diagnostics$unexpected_unmatched_identifiers[[1]],
    fake_county
  )
})

test_that("covariate joins distinguish years outside INKAR coverage", {
  covs <- gerda_covariates()
  real_county <- covs$county_code[[1]]
  input <- data.frame(
    county_code = rep(real_county, 3),
    election_year = c(1994, 2020, 2023)
  )

  result <- NULL
  expect_message(
    result <- add_gerda_covariates(input, unmatched = "error"),
    "2 row\\(s\\) across 1 unit\\(s\\) fall outside the 1995-2022"
  )
  diagnostics <- gerda_join_diagnostics(result)

  expect_equal(diagnostics$eligible_rows, 1L)
  expect_equal(diagnostics$matched_rows, 1L)
  expect_equal(diagnostics$unmatched_rows, 2L)
  expect_equal(diagnostics$outside_coverage_rows, 2L)
  expect_equal(diagnostics$unexpected_unmatched_rows, 0L)
  expect_equal(diagnostics$outside_coverage_units, 1L)
  expect_equal(diagnostics$eligible_match_rate, 1)
  expect_equal(diagnostics$coverage_start, 1995L)
  expect_equal(diagnostics$coverage_end, 2022L)
  expect_equal(diagnostics$outside_coverage_years[[1]], c(1994L, 2023L))
})

test_that("unmatched controls warning, error, and ignore behavior", {
  input <- data.frame(
    county_code = "99999",
    election_year = 2020
  )

  expect_error(
    add_gerda_covariates(input, unmatched = "error"),
    "1 of 1 eligible row\\(s\\)"
  )
  ignored <- expect_warning(
    add_gerda_covariates(input, unmatched = "ignore"),
    NA
  )
  diagnostics <- gerda_join_diagnostics(ignored)
  expect_equal(diagnostics$unexpected_unmatched_rows, 1L)
  expect_equal(diagnostics$unmatched_action, "ignore")
})

test_that("census joins report unmatched and missing identifiers", {
  census <- gerda_census()
  fake_ags <- "99999999"
  expect_false(fake_ags %in% census$ags)
  input <- data.frame(
    ags = c(census$ags[[1]], fake_ags, NA_character_),
    value = 1:3
  )

  result <- NULL
  expect_warning(
    result <- add_gerda_census(input),
    "2 of 3 eligible row\\(s\\) across 1 unit\\(s\\)"
  )
  diagnostics <- gerda_join_diagnostics(result)

  expect_equal(nrow(result), nrow(input))
  expect_equal(result$value, input$value)
  expect_equal(diagnostics$helper, "add_gerda_census")
  expect_equal(diagnostics$data_level, "municipality")
  expect_equal(diagnostics$matched_rows, 1L)
  expect_equal(diagnostics$unmatched_rows, 2L)
  expect_equal(diagnostics$outside_coverage_rows, 0L)
  expect_equal(diagnostics$unexpected_unmatched_rows, 2L)
  expect_equal(diagnostics$missing_key_rows, 1L)
  expect_equal(diagnostics$unexpected_unmatched_identifiers[[1]], fake_ags)
})

test_that("join diagnostics accumulate across helper calls", {
  covs <- gerda_covariates()
  census <- gerda_census()
  census_counties <- substr(census$ags, 1, 5)
  usable <- census$ags[census_counties %in% covs$county_code][[1]]
  county <- substr(usable, 1, 5)
  year <- covs$year[covs$county_code == county][[1]]
  input <- data.frame(ags = usable, election_year = year)

  with_covariates <- suppressMessages(
    add_gerda_covariates(input, unmatched = "error")
  )
  result <- add_gerda_census(with_covariates, unmatched = "error")
  diagnostics <- gerda_join_diagnostics(result)

  expect_equal(
    diagnostics$helper,
    c("add_gerda_covariates", "add_gerda_census")
  )
  expect_equal(diagnostics$data_level, c("municipality", "municipality"))
  expect_equal(diagnostics$matched_rows, c(1L, 1L))
  expect_equal(diagnostics$output_rows, c(1L, 1L))
})

test_that("gerda_join_diagnostics requires a GERDA join result", {
  expect_error(
    gerda_join_diagnostics(data.frame(x = 1)),
    "does not contain GERDA join diagnostics"
  )
  expect_error(
    gerda_join_diagnostics(1),
    "must be a data frame"
  )
})
