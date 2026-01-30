#' Get Municipality-Level Census 2022 Data
#'
#' @description
#' Returns municipality-level demographic and socioeconomic data from the
#' German Census 2022 (Zensus 2022). This is a cross-sectional snapshot
#' covering all German municipalities.
#'
#' For most users, we recommend using \code{\link{add_gerda_census}} instead,
#' which automatically merges census data with GERDA election data.
#'
#' @return A data frame with approximately 11,000 rows (one per municipality)
#'   and 21 columns containing census indicators. See
#'   \code{\link{gerda_census_codebook}} for variable descriptions.
#'
#' @details
#' The dataset includes:
#' \itemize{
#'   \item Demographics: Population, age structure
#'   \item Migration: Migration background, foreign nationals
#'   \item Religion: Catholic, Protestant, Muslim, no affiliation
#'   \item Households: Average household size
#'   \item Housing: Dwellings, vacancy, ownership, rents, building types
#'   \item Education: Share with university degree
#' }
#'
#' Municipality codes are 8-digit AGS codes. Since the census is a single
#' 2022 snapshot, there is no year dimension.
#'
#' @examples
#' # Get the census data
#' census <- gerda_census()
#' head(census)
#'
#' # Check available municipalities
#' nrow(census)
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{add_gerda_census}} for automatic merging with election data
#'   \item \code{\link{gerda_census_codebook}} for variable descriptions
#' }
#'
#' @export
gerda_census <- function() {
  return(census_2022_internal)
}


#' Get Codebook for Census 2022 Data
#'
#' @description
#' Returns the data dictionary for municipality-level Census 2022 indicators.
#' Provides variable names, labels, units, and data sources.
#'
#' @return A data frame with 21 rows documenting all variables in the census
#'   dataset.
#'
#' @examples
#' # View the codebook
#' codebook <- gerda_census_codebook()
#' print(codebook)
#'
#' @seealso \code{\link{gerda_census}} for the actual census data
#'
#' @export
gerda_census_codebook <- function() {
  return(census_2022_codebook_internal)
}


#' Add Census 2022 Data to GERDA Election Data
#'
#' @description
#' Convenience function to merge Zensus 2022 municipality-level data with
#' GERDA election data. The census provides a cross-sectional snapshot (2022),
#' so the same values are attached to all election years.
#'
#' The function works with both municipality-level and county-level election data:
#' \itemize{
#'   \item \strong{Municipality-level data}: Direct merge using 8-digit AGS codes
#'   \item \strong{County-level data}: Census data is aggregated to the county level
#'         (population-weighted means for shares, sums for counts) before merging
#' }
#'
#' @param election_data A data frame containing GERDA election data. Must contain
#'   either an \code{ags} column (municipality level) or a \code{county_code}
#'   column (county level).
#'
#' @return The input data frame with additional census columns appended. The
#'   number of rows remains unchanged (left join).
#'
#' @details
#' ## Required Columns
#' The input data must contain one of:
#' \itemize{
#'   \item \code{ags}: 8-digit municipal code for municipality-level data
#'   \item \code{county_code}: 5-digit county code for county-level data
#' }
#'
#' ## Merge Behavior
#' Since the census is a 2022 cross-section, census values are the same for all
#' election years. The merge is on geography only (no year join).
#'
#' For county-level data, municipality-level census data is first aggregated:
#' \itemize{
#'   \item Share variables: Population-weighted means
#'   \item Count variables (population, total_dwellings): Sums
#'   \item Other variables (avg_household_size, avg_rent_per_m2): Population-weighted means
#' }
#'
#' @examples
#' \dontrun{
#' library(gerda)
#'
#' # Municipality-level merge
#' muni_data <- load_gerda_web("federal_muni_harm_21") |>
#'   add_gerda_census()
#'
#' # County-level merge (aggregated from municipalities)
#' county_data <- load_gerda_web("federal_cty_harm") |>
#'   add_gerda_census()
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{gerda_census}} for direct access to the census data
#'   \item \code{\link{gerda_census_codebook}} for variable descriptions
#' }
#'
#' @export
add_gerda_census <- function(election_data) {
  # Avoid NOTE in R CMD check for NSE variables
  ags <- county_code <- county_code_temp <- population <- NULL

  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }

  has_ags <- "ags" %in% names(election_data)
  has_county_code <- "county_code" %in% names(election_data)

  if (!has_ags && !has_county_code) {
    stop("election_data must contain either 'ags' (for municipal-level data) or 'county_code' (for county-level data)")
  }

  # Get census data
  census <- gerda_census()

  # Remove municipality_name to avoid conflicts
  census_merge <- census %>%
    dplyr::select(-dplyr::any_of("municipality_name"))

  if (has_ags) {
    # Municipality-level: direct merge on AGS
    if (has_county_code) {
      message("Both 'ags' and 'county_code' found. Using 'ags' for municipality-level merge.")
    }

    result <- election_data %>%
      dplyr::left_join(census_merge, by = "ags")

  } else {
    # County-level: aggregate census to county, then merge
    message(
      "Aggregating municipality-level census data to county level.\n",
      "Share variables are population-weighted means; counts are sums."
    )

    # Identify share vs count columns
    share_cols <- grep("^share_|^avg_|vacancy_rate", names(census_merge), value = TRUE)
    count_cols <- c("population", "total_dwellings")

    # Aggregate to county level
    census_county <- census_merge %>%
      dplyr::mutate(county_code_temp = substr(ags, 1, 5)) %>%
      dplyr::group_by(county_code_temp) %>%
      dplyr::summarize(
        dplyr::across(
          dplyr::all_of(count_cols),
          ~ sum(.x, na.rm = TRUE),
          .names = "census_{.col}"
        ),
        dplyr::across(
          dplyr::all_of(share_cols),
          ~ stats::weighted.mean(.x, w = population, na.rm = TRUE),
          .names = "census_{.col}"
        ),
        .groups = "drop"
      ) %>%
      dplyr::rename(county_code = county_code_temp)

    result <- election_data %>%
      dplyr::left_join(census_county, by = "county_code")
  }

  return(result)
}
