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
#' @return A data frame with 11,200 rows and 22 columns containing county-level
#'   covariates for 400 German counties from 1995 to 2022. See
#'   \code{\link{gerda_covariates_codebook}} for variable descriptions.
#'
#' @details
#' The dataset includes 20 socioeconomic and demographic variables:
#' \itemize{
#'   \item Demographics: Age structure, foreign population, gender
#'   \item Economy: GDP, sectoral composition, enterprise structure
#'   \item Labor Market: Unemployment rates (overall, youth, long-term)
#'   \item Education: School completion rates, students, apprentices
#'   \item Income: Median income, purchasing power, low-income households
#' }
#'
#' County codes are formatted as 5-digit AGS codes matching GERDA's harmonized
#' county codes (2021 boundaries).
#'
#' @examples
#' # Get the covariates data
#' covs <- gerda_covariates()
#'
#' # Inspect the data
#' head(covs)
#' summary(covs)
#'
#' # Manual merge (advanced)
#' library(dplyr)
#' elections <- load_gerda_web("federal_cty_harm")
#' merged <- elections %>%
#'   left_join(covs, by = c("county_code" = "county_code", "election_year" = "year"))
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
#' @return A data frame with 22 rows documenting all variables in the county
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
#'
#' @return The input data frame with additional columns for all 20 county-level
#'   covariates. The number of rows remains unchanged (left join).
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
#' # Verify: municipalities in same county have same covariate values
#' muni_data %>%
#'   group_by(county_code_21, election_year) %>%
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
#' }
#'
#' @export
add_gerda_covariates <- function(election_data) {
  # Avoid NOTE in R CMD check for NSE variables
  ags <- county_code_temp <- NULL

  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }

  if (!"election_year" %in% names(election_data)) {
    stop("election_data must contain an 'election_year' column")
  }

  # Detect data level (county or municipal)
  has_county_code <- "county_code" %in% names(election_data)
  has_ags <- "ags" %in% names(election_data)

  if (!has_county_code && !has_ags) {
    stop("election_data must contain either 'county_code' (for county-level data) or 'ags' (for municipal-level data)")
  }

  # Get covariates
  covs <- gerda_covariates()

  # Handle based on data level
  if (has_county_code) {
    # County-level data: direct merge
    result <- election_data %>%
      dplyr::left_join(
        covs,
        by = c("county_code" = "county_code", "election_year" = "year")
      )
  } else {
    # Municipal-level data: extract county code and merge
    message(
      "Merging county-level covariates to municipal-level data.\n",
      "Note: All municipalities within the same county will have identical covariate values."
    )

    result <- election_data %>%
      dplyr::mutate(county_code_temp = substr(ags, 1, 5)) %>%
      dplyr::left_join(
        covs,
        by = c("county_code_temp" = "county_code", "election_year" = "year")
      ) %>%
      dplyr::select(-county_code_temp)
  }

  return(result)
}
