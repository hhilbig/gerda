#' Get County-Level Covariates from INKAR
#'
#' @description
#' Returns county-level socioeconomic and demographic covariates from INKAR.
#' This function provides flexible access to the raw covariate data for
#' advanced users who want to inspect or manipulate it before merging with
#' county-level election data.
#'
#' For most users, we recommend using \code{\link{add_gerda_covariates}} instead,
#' which automatically performs the merge with correct join keys.
#'
#' \strong{Note}: These covariates are at the county (Kreis) level and should be
#' merged with county-level GERDA data (e.g., \code{federal_cty_harm}).
#'
#' @return A data frame with 11,200 rows and 32 columns containing county-level
#'   covariates for 400 German counties from 1995 to 2022. See
#'   \code{\link{gerda_covariates_codebook}} for variable descriptions.
#'
#' @details
#' The dataset includes 30 socioeconomic and demographic variables:
#' \itemize{
#'   \item Demographics: Age structure, foreign population, gender
#'   \item Economy: GDP, sectoral composition, enterprise structure
#'   \item Labor Market: Unemployment rates (overall, youth, long-term)
#'   \item Education: School completion rates, students, apprentices
#'   \item Income: Purchasing power, low-income households
#'   \item Healthcare: Physician density, hospital beds, GP density
#'   \item Childcare: Coverage rates for under-3 and 3-6 age groups
#'   \item Housing: Building permits, rent levels, living space
#'   \item Transport: Cars per capita
#'   \item Public Finances: Municipal debt, tax revenue
#' }
#'
#' County codes are formatted as 5-digit AGS codes matching GERDA's harmonized
#' county codes (2021 boundaries).
#'
#' @examples
#' # Get the covariates data (bundled, no network call)
#' covs <- gerda_covariates()
#'
#' # Inspect the data
#' head(covs)
#' summary(covs)
#'
#' \donttest{
#' # Manual merge (advanced) — downloads election data from GitHub
#' library(dplyr)
#' elections <- load_gerda_web("federal_cty_harm")
#' merged <- elections %>%
#'   left_join(covs, by = c("county_code" = "county_code", "election_year" = "year"))
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{add_gerda_covariates}} for automatic merging (recommended)
#'   \item \code{\link{gerda_covariates_codebook}} for variable descriptions
#' }
#'
#' @export
gerda_covariates <- function() {
  return(county_covariates_internal)
}


#' Get Codebook for County-Level Covariates
#'
#' @description
#' Returns the data dictionary for county-level (Kreis) covariates from INKAR.
#' Provides variable names, labels, units, categories, original INKAR codes,
#' and missing data information for all county-level socioeconomic and
#' demographic indicators.
#'
#' @return A data frame with 32 rows documenting all variables in the county
#'   covariates dataset.
#'
#' @examples
#' # View the full codebook
#' codebook <- gerda_covariates_codebook()
#' print(codebook)
#'
#' # Find variables by category
#' library(dplyr)
#' codebook %>%
#'   filter(category == "Demographics")
#'
#' # Find variables with good coverage
#' codebook %>%
#'   filter(missing_pct < 5)
#'
#' @seealso \code{\link{gerda_covariates}} for the actual covariate data
#'
#' @export
gerda_covariates_codebook <- function() {
  return(covariates_codebook_internal)
}


#' Add County-Level Covariates to GERDA Election Data
#'
#' @description
#' Convenience function to merge INKAR county-level (Kreis) covariates with
#' GERDA election data. This is the recommended way to add covariates, as it
#' automatically uses the correct join keys and prevents common merge errors.
#'
#' The function works with both county-level and municipal-level election data:
#' \itemize{
#'   \item \strong{County-level data}: Direct merge using county codes
#'   \item \strong{Municipal-level data}: Automatically extracts county code
#'         from municipal AGS (first 5 digits) and merges
#' }
#'
#' \strong{Important}: Covariates are always at the county level. When merging
#' with municipal data, all municipalities within the same county will receive
#' identical covariate values.
#'
#' The function performs a left join, keeping all rows from the election data
#' and adding covariates where available. This automatically retains only
#' election years.
#'
#' @param election_data A data frame containing GERDA election data. Must
#'   contain a column with county or municipal codes (see Details) and
#'   \code{election_year}.
#' @param unmatched How to handle rows within the 1995-2022 INKAR coverage
#'   window whose join keys do not match. One of `"warn"` (default), `"error"`,
#'   or `"ignore"`. Rows outside 1995-2022 are reported separately and do not
#'   trigger this action.
#'
#' @return The input data frame with additional columns for all 30 county-level
#'   covariates. The number of rows remains unchanged. A machine-readable join
#'   report is attached and can be retrieved with [gerda_join_diagnostics()].
#'
#' @details
#' ## Required Columns
#' The input data must contain \code{election_year} and one of:
#' \itemize{
#'   \item \code{county_code}: 5-digit county code (AGS) for county-level data
#'   \item \code{ags}: 8-digit municipal code (AGS) for municipal-level data
#' }
#'
#' The function automatically detects which column is present and performs the
#' appropriate merge. For municipal data, the county code is extracted from the
#' first 5 digits of the AGS.
#'
#' ## Data Level
#' Covariates are at the county (Kreis) level:
#' \itemize{
#'   \item \strong{County-level merge}: One-to-one match, each county gets its covariates
#'   \item \strong{Municipal-level merge}: Many-to-one match, all municipalities in the
#'         same county receive identical covariate values
#' }
#'
#' ## Data Availability
#' Covariates are available from 1995-2022. For GERDA federal elections:
#' \itemize{
#'   \item Elections 1990, 1994: No covariates (before 1995)
#'   \item Elections 1998-2021: Covariates available
#' }
#'
#' ## Missing Data
#' Some covariates have missing values. Use \code{gerda_covariates_codebook()}
#' to check data availability for specific variables.
#'
#' ## Validation and Diagnostics
#' Geographic identifiers must be character vectors containing exactly five
#' digits (`county_code`) or eight digits (`ags`). Numeric identifiers are
#' rejected because leading zeros may already have been lost. Before joining,
#' the function verifies reference-key uniqueness and rejects output-column
#' conflicts. It then verifies that the join has not changed the input row
#' count and reports unexpected unmatched rows separately from years outside
#' INKAR coverage. Missing join keys are always classified as unexpected. Use
#' `unmatched = "error"` in unattended pipelines.
#'
#' @examples
#' \dontrun{
#' library(gerda)
#' library(dplyr)
#'
#' # Example 1: County-level election data
#' county_data <- load_gerda_web("federal_cty_harm") %>%
#'   add_gerda_covariates()
#'
#' # Check the result
#' names(county_data) # See new covariate columns
#' table(county_data$election_year) # Only election years
#'
#' # Example 2: Municipal-level election data
#' # Note: All municipalities in the same county will get identical covariates
#' muni_data <- load_gerda_web("federal_muni_harm_21") %>%
#'   add_gerda_covariates()
#'
#' # Verify: municipalities in same county have same covariate values.
#' # The county code is the first 5 digits of the 8-digit municipal AGS.
#' muni_data %>%
#'   mutate(county_code = substr(ags, 1, 5)) %>%
#'   group_by(county_code, election_year) %>%
#'   summarize(
#'     n_munis = n(),
#'     unemp_range = max(unemployment_rate) - min(unemployment_rate)
#'   )
#'
#' # Analyze with covariates
#' county_data %>%
#'   filter(election_year == 2021) %>%
#'   filter(!is.na(unemployment_rate)) %>%
#'   summarize(cor_unemployment_afd = cor(unemployment_rate, afd))
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{gerda_covariates}} for direct access to the covariate data
#'   \item \code{\link{gerda_covariates_codebook}} for variable descriptions
#'   \item \code{\link{load_gerda_web}} for loading GERDA election data
#'   \item \code{\link{gerda_join_diagnostics}} for inspecting match results
#' }
#'
#' @export
add_gerda_covariates <- function(election_data, unmatched = "warn") {
  # Avoid NOTE in R CMD check for NSE variables
  ags <- NULL

  unmatched <- validate_gerda_unmatched(unmatched)

  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }

  if (!"election_year" %in% names(election_data)) {
    stop("election_data must contain an 'election_year' column")
  }
  validate_gerda_year(election_data$election_year)

  # Detect data level (county or municipal)
  has_county_code <- "county_code" %in% names(election_data)
  has_ags <- "ags" %in% names(election_data)

  if (!has_county_code && !has_ags) {
    stop("election_data must contain either 'county_code' (for county-level data) or 'ags' (for municipal-level data)")
  }

  if (has_county_code && has_ags) {
    message("Both 'county_code' and 'ags' found. Using 'county_code' for merge.")
  }

  identifier_name <- if (has_county_code) "county_code" else "ags"
  identifier_width <- if (has_county_code) 5L else 8L
  validate_gerda_identifier(
    election_data[[identifier_name]], identifier_name, identifier_width
  )

  # Get covariates
  covs <- gerda_covariates()
  validate_gerda_identifier(covs$county_code, "county_code", 5L)
  validate_gerda_year(covs$year, "year")
  validate_gerda_join_key(
    covs, c("county_code", "year"), "GERDA covariates"
  )
  assert_no_gerda_join_conflicts(
    election_data, covs, c("county_code", "year"),
    "add_gerda_covariates"
  )

  coverage_start <- min(covs$year)
  coverage_end <- max(covs$year)
  input_rows <- nrow(election_data)

  # Handle based on data level
  if (has_county_code) {
    # County-level data: direct merge
    join_input <- election_data
    input_keys <- c("county_code", "election_year")
    reference_keys <- c("county_code", "year")
    matched <- gerda_match_keys(
      join_input, covs, input_keys, reference_keys
    )
    result <- join_input %>%
      dplyr::left_join(
        covs,
        by = c("county_code" = "county_code", "election_year" = "year")
      )
    report_keys <- c("county_code = county_code", "election_year = year")
    data_level <- "county"
  } else {
    # Municipal-level data: extract county code and merge
    message(
      "Merging county-level covariates to municipal-level data.\n",
      "Note: All municipalities within the same county will have identical covariate values."
    )

    temporary_key <- gerda_temp_name(names(election_data))
    join_input <- election_data
    join_input[[temporary_key]] <- substr(join_input$ags, 1, 5)
    input_keys <- c(temporary_key, "election_year")
    reference_keys <- c("county_code", "year")
    matched <- gerda_match_keys(
      join_input, covs, input_keys, reference_keys
    )
    by <- stats::setNames(reference_keys, input_keys)
    result <- join_input %>%
      dplyr::left_join(
        covs,
        by = by
      ) %>%
      dplyr::select(-dplyr::all_of(temporary_key))
    report_keys <- c("substr(ags, 1, 5) = county_code", "election_year = year")
    data_level <- "municipality"
  }

  assert_gerda_row_count(input_rows, nrow(result), "add_gerda_covariates")

  missing_keys <- !stats::complete.cases(join_input[input_keys])
  outside_coverage <- !missing_keys &
    (election_data$election_year < coverage_start |
       election_data$election_year > coverage_end)
  outside_coverage[is.na(outside_coverage)] <- FALSE

  report <- make_gerda_join_report(
    helper = "add_gerda_covariates",
    data_level = data_level,
    identifier_name = identifier_name,
    identifier = election_data[[identifier_name]],
    join_keys = report_keys,
    matched = matched,
    outside_coverage = outside_coverage,
    missing_keys = missing_keys,
    output_rows = nrow(result),
    unmatched_action = unmatched,
    coverage_start = coverage_start,
    coverage_end = coverage_end,
    outside_years = election_data$election_year[outside_coverage]
  )
  result <- attach_gerda_join_report(result, election_data, report)
  signal_gerda_join_report(report)

  return(result)
}
