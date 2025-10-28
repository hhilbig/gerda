#' Get County-Level Covariates
#'
#' @description
#' Returns the INKAR county-level covariates dataset. This function provides
#' flexible access to the raw covariate data for advanced users who want to
#' inspect or manipulate it before merging with election data.
#'
#' For most users, we recommend using \code{\link{add_gerda_covariates}} instead,
#' which automatically performs the merge with correct join keys.
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


#' Get Codebook for County Covariates
#'
#' @description
#' Returns the data dictionary for county-level covariates. Provides variable
#' names, labels, units, categories, original INKAR codes, and missing data
#' information.
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


#' Add County Covariates to GERDA Election Data
#'
#' @description
#' Convenience function to merge INKAR county-level covariates with GERDA
#' election data. This is the recommended way to add covariates, as it
#' automatically uses the correct join keys and prevents common merge errors.
#'
#' The function performs a left join, keeping all rows from the election data
#' and adding covariates where available. This automatically retains only
#' election years.
#'
#' @param election_data A data frame containing GERDA election data at the
#'   county level. Must contain columns \code{county_code} and
#'   \code{election_year}.
#'
#' @return The input data frame with additional columns for all 20 county-level
#'   covariates. The number of rows remains unchanged (left join).
#'
#' @details
#' ## Required Columns
#' The input data must contain:
#' \itemize{
#'   \item \code{county_code}: 5-digit county code (AGS)
#'   \item \code{election_year}: Year of election
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
#' # Load election data and add covariates
#' merged <- load_gerda_web("federal_cty_harm") %>%
#'   add_gerda_covariates()
#'
#' # Check the result
#' names(merged)  # See new covariate columns
#' table(merged$election_year)  # Only election years
#'
#' # Analyze with covariates
#' merged %>%
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
  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }
  
  if (!"county_code" %in% names(election_data)) {
    stop("election_data must contain a 'county_code' column")
  }
  
  if (!"election_year" %in% names(election_data)) {
    stop("election_data must contain an 'election_year' column")
  }
  
  # Get covariates
  covs <- gerda_covariates()
  
  # Perform left join
  result <- election_data %>%
    dplyr::left_join(
      covs,
      by = c("county_code" = "county_code", "election_year" = "year")
    )
  
  return(result)
}

