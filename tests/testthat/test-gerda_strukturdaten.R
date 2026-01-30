test_that("gerda_strukturdaten returns a data frame with expected structure", {
  struk <- gerda_strukturdaten()

  expect_s3_class(struk, "data.frame")
  expect_gt(nrow(struk), 0)
  expect_true("county_code" %in% names(struk))
  expect_true("election_year" %in% names(struk))
  expect_true("settlement_area_pct" %in% names(struk))
  expect_true("gdp_per_capita" %in% names(struk))
  expect_true("cars_per_1k" %in% names(struk))
  expect_true("sgb2_recipients_pct" %in% names(struk))

  # Should have data for multiple election years
  expect_gt(length(unique(struk$election_year)), 1)
})

test_that("gerda_strukturdaten_codebook returns a data frame with expected structure", {
  codebook <- gerda_strukturdaten_codebook()

  expect_s3_class(codebook, "data.frame")
  expect_gt(nrow(codebook), 0)
  expect_true(all(c("variable", "label", "unit", "source") %in% names(codebook)))

  # All strukturdaten variables should be documented
  struk <- gerda_strukturdaten()
  struk_vars <- names(struk)
  documented_vars <- codebook$variable
  expect_true(all(struk_vars %in% documented_vars))
})

test_that("add_gerda_strukturdaten validates input", {
  expect_error(add_gerda_strukturdaten("not a data frame"), "must be a data frame")

  # Missing election_year
  bad_data <- data.frame(county_code = "01001")
  expect_error(add_gerda_strukturdaten(bad_data), "must contain an 'election_year' column")

  # Missing geographic column
  bad_data2 <- data.frame(election_year = 2021)
  expect_error(add_gerda_strukturdaten(bad_data2), "must contain either")
})

test_that("add_gerda_strukturdaten works with county-level data", {
  struk <- gerda_strukturdaten()
  sample_counties <- head(unique(struk$county_code), 3)
  sample_year <- struk$election_year[1]

  county_data <- data.frame(
    county_code = sample_counties,
    election_year = sample_year,
    votes = c(1000, 2000, 1500),
    stringsAsFactors = FALSE
  )

  result <- add_gerda_strukturdaten(county_data)

  # Should keep all original rows
  expect_equal(nrow(result), nrow(county_data))

  # Should add structural data columns
  expect_true("settlement_area_pct" %in% names(result))
  expect_true("gdp_per_capita" %in% names(result))

  # Original columns preserved
  expect_true("votes" %in% names(result))
})

test_that("add_gerda_strukturdaten works with municipal-level data", {
  struk <- gerda_strukturdaten()
  sample_counties <- head(unique(struk$county_code), 2)
  sample_year <- struk$election_year[1]

  # Create mock municipal data with 8-digit AGS
  muni_data <- data.frame(
    ags = paste0(sample_counties, "001"),
    election_year = sample_year,
    votes = c(100, 200),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(add_gerda_strukturdaten(muni_data))

  # Should keep all original rows
  expect_equal(nrow(result), nrow(muni_data))

  # Should add structural data columns
  expect_true("settlement_area_pct" %in% names(result))
  expect_true("gdp_per_capita" %in% names(result))
})

test_that("add_gerda_strukturdaten returns NA for unmatched years", {
  struk <- gerda_strukturdaten()
  sample_county <- unique(struk$county_code)[1]

  # Use an election year that's unlikely to have structural data
  county_data <- data.frame(
    county_code = sample_county,
    election_year = 1990,
    stringsAsFactors = FALSE
  )

  result <- add_gerda_strukturdaten(county_data)

  # Structural columns should be NA for 1990
  expect_true(is.na(result$settlement_area_pct))
})

test_that("add_gerda_strukturdaten prefers county_code over ags when both present", {
  struk <- gerda_strukturdaten()
  sample_county <- unique(struk$county_code)[1]
  sample_year <- struk$election_year[1]

  both_data <- data.frame(
    county_code = sample_county,
    ags = paste0(sample_county, "001"),
    election_year = sample_year,
    stringsAsFactors = FALSE
  )

  expect_message(add_gerda_strukturdaten(both_data), "Using 'county_code'")
})
