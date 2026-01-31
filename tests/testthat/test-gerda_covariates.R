test_that("gerda_covariates returns a data frame with expected structure", {
  covs <- gerda_covariates()

  expect_s3_class(covs, "data.frame")
  expect_gt(nrow(covs), 0)
  expect_true("county_code" %in% names(covs))
  expect_true("year" %in% names(covs))
  expect_true("unemployment_rate" %in% names(covs))
  expect_true("gdp_per_capita" %in% names(covs))
  expect_true("share_foreign" %in% names(covs))
})

test_that("gerda_covariates_codebook returns a data frame with expected structure", {
  codebook <- gerda_covariates_codebook()

  expect_s3_class(codebook, "data.frame")
  expect_gt(nrow(codebook), 0)
  expect_true(all(c("variable", "label") %in% names(codebook)))

  # All covariate variables should be documented
  covs <- gerda_covariates()
  cov_vars <- names(covs)
  documented_vars <- codebook$variable
  expect_true(all(cov_vars %in% documented_vars))
})

test_that("add_gerda_covariates validates input", {
  expect_error(add_gerda_covariates("not a data frame"), "must be a data frame")

  # Missing election_year
  bad_data <- data.frame(county_code = "05111", x = 1)
  expect_error(add_gerda_covariates(bad_data), "election_year")

  # Missing geographic columns
  bad_data2 <- data.frame(election_year = 2017, x = 1)
  expect_error(add_gerda_covariates(bad_data2), "must contain either")
})

test_that("add_gerda_covariates works with county-level data", {
  covs <- gerda_covariates()
  sample_counties <- unique(covs$county_code)[1:5]
  sample_year <- covs$year[1]

  county_data <- data.frame(
    county_code = sample_counties,
    election_year = sample_year,
    votes = c(100, 200, 150, 300, 250),
    stringsAsFactors = FALSE
  )

  result <- add_gerda_covariates(county_data)

  # Should keep all original rows
  expect_equal(nrow(result), nrow(county_data))

  # Should add covariate columns
  expect_true("unemployment_rate" %in% names(result))
  expect_true("gdp_per_capita" %in% names(result))

  # Original columns should be preserved
  expect_true("votes" %in% names(result))
  expect_true("election_year" %in% names(result))
})

test_that("add_gerda_covariates works with municipal-level data", {
  covs <- gerda_covariates()
  sample_county <- unique(covs$county_code)[1]
  sample_year <- covs$year[1]

  # Create mock municipal data with 8-digit AGS derived from a real county code
  muni_data <- data.frame(
    ags = paste0(sample_county, c("001", "002", "003")),
    election_year = sample_year,
    votes = c(100, 200, 150),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(add_gerda_covariates(muni_data))

  # Should keep all original rows
  expect_equal(nrow(result), nrow(muni_data))

  # Should add covariate columns
  expect_true("unemployment_rate" %in% names(result))

  # All municipalities in same county should get identical covariate values
  unemp_vals <- result$unemployment_rate
  expect_true(length(unique(unemp_vals)) == 1)

  # Temporary county_code_temp column should be removed
  expect_false("county_code_temp" %in% names(result))

  # Original columns should be preserved
  expect_true("votes" %in% names(result))
})

test_that("add_gerda_covariates prefers county_code over ags when both present", {
  covs <- gerda_covariates()
  sample_county <- unique(covs$county_code)[1]
  sample_year <- covs$year[1]

  both_data <- data.frame(
    county_code = sample_county,
    ags = paste0(sample_county, "001"),
    election_year = sample_year,
    stringsAsFactors = FALSE
  )

  # Should use county_code and emit a message
  expect_message(add_gerda_covariates(both_data), "Using 'county_code'")
})

test_that("add_gerda_covariates returns NAs for unmatched years", {
  covs <- gerda_covariates()
  sample_county <- unique(covs$county_code)[1]

  # Use a year outside the covariate range
  county_data <- data.frame(
    county_code = sample_county,
    election_year = 1960,
    stringsAsFactors = FALSE
  )

  result <- add_gerda_covariates(county_data)

  expect_equal(nrow(result), 1)
  expect_true(is.na(result$unemployment_rate))
})
