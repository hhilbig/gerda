#' Get Bundeswahlleiter Structural Data
#'
#' @description
#' Returns county-level structural indicators published by the Federal
#' Returning Officer (Bundeswahlleiterin) for each federal election.
#' Data covers land use, housing, transport, childcare, economic output,
#' social benefits, and school qualifications.
#'
#' For most users, we recommend using \code{\link{add_gerda_strukturdaten}}
#' instead, which automatically merges structural data with GERDA election data.
#'
#' @return A data frame with approximately 1,600 rows (400 counties times
#'   4 election years) and 12 columns. See
#'   \code{\link{gerda_strukturdaten_codebook}} for variable descriptions.
#'
#' @details
#' The dataset includes:
#' \itemize{
#'   \item Land use: Settlement, agricultural, and forest area shares
#'   \item Housing: Completed dwellings per capita
#'   \item Transport: Cars per capita
#'   \item Childcare: Daycare coverage
#'   \item Economy: GDP per capita
#'   \item Social: SGB II benefit recipients
#'   \item Education: School leaver qualifications
#' }
#'
#' Data is available for federal election years 2013, 2017, 2021, and 2025.
#' County codes are 5-digit AGS codes matching GERDA's harmonized county codes.
#'
#' @examples
#' # Get the structural data
#' struk <- gerda_strukturdaten()
#' head(struk)
#'
#' # See available election years
#' unique(struk$election_year)
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{add_gerda_strukturdaten}} for automatic merging (recommended)
#'   \item \code{\link{gerda_strukturdaten_codebook}} for variable descriptions
#' }
#'
#' @export
gerda_strukturdaten <- function() {
  return(strukturdaten_internal)
}


#' Get Codebook for Structural Data
#'
#' @description
#' Returns the data dictionary for the Bundeswahlleiter structural data.
#' Provides variable names, labels, units, and data sources.
#'
#' @return A data frame with 12 rows documenting all variables in the
#'   structural dataset.
#'
#' @examples
#' # View the codebook
#' codebook <- gerda_strukturdaten_codebook()
#' print(codebook)
#'
#' @seealso \code{\link{gerda_strukturdaten}} for the actual data
#'
#' @export
gerda_strukturdaten_codebook <- function() {
  return(strukturdaten_codebook_internal)
}


#' Add Structural Data to GERDA Election Data
#'
#' @description
#' Convenience function to merge Bundeswahlleiter structural data with GERDA
#' election data. The function matches on county code and election year.
#'
#' For election years without structural data, the nearest available year is
#' used.
#'
#' The function works with both county-level and municipal-level election data:
#' \itemize{
#'   \item \strong{County-level data}: Direct merge on county code and election year
#'   \item \strong{Municipal-level data}: Extracts county code from the
#'         8-digit AGS (first 5 digits) and merges. All municipalities within
#'         the same county receive identical structural data values.
#' }
#'
#' @param election_data A data frame containing GERDA election data. Must contain
#'   \code{election_year} and either \code{county_code} (county level) or
#'   \code{ags} (municipal level).
#'
#' @return The input data frame with additional structural data columns appended.
#'   The number of rows remains unchanged (left join).
#'
#' @details
#' ## Available Election Years
#' Structural data is available for 2013, 2017, 2021, and 2025. For other
#' election years, no structural data is merged (columns will be NA).
#'
#' @examples
#' \dontrun{
#' library(gerda)
#'
#' # County-level
#' county_data <- load_gerda_web("federal_cty_harm") |>
#'   add_gerda_strukturdaten()
#'
#' # Municipal-level (all munis in same county get same values)
#' muni_data <- load_gerda_web("federal_muni_harm_21") |>
#'   add_gerda_strukturdaten()
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{gerda_strukturdaten}} for direct access
#'   \item \code{\link{gerda_strukturdaten_codebook}} for variable descriptions
#' }
#'
#' @export
add_gerda_strukturdaten <- function(election_data) {
  # Avoid NOTE in R CMD check for NSE variables
  ags <- county_code <- county_code_temp <- election_year <- NULL

  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }

  if (!"election_year" %in% names(election_data)) {
    stop("election_data must contain an 'election_year' column")
  }

  has_county_code <- "county_code" %in% names(election_data)
  has_ags <- "ags" %in% names(election_data)

  if (!has_county_code && !has_ags) {
    stop("election_data must contain either 'county_code' (for county-level data) or 'ags' (for municipal-level data)")
  }

  # Get structural data
  struk <- gerda_strukturdaten()

  if (has_county_code) {
    if (has_ags) {
      message("Both 'county_code' and 'ags' found. Using 'county_code' for merge.")
    }

    # County-level: direct merge on county_code + election_year
    result <- election_data %>%
      dplyr::left_join(
        struk,
        by = c("county_code" = "county_code", "election_year" = "election_year")
      )

  } else {
    # Municipal-level: extract county code and merge
    message(
      "Merging county-level structural data to municipal-level data.\n",
      "Note: All municipalities within the same county will have identical values."
    )

    result <- election_data %>%
      dplyr::mutate(county_code_temp = substr(ags, 1, 5)) %>%
      dplyr::left_join(
        struk,
        by = c("county_code_temp" = "county_code", "election_year" = "election_year")
      ) %>%
      dplyr::select(-county_code_temp)
  }

  return(result)
}
