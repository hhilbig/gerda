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
#' @return A data frame with approximately 10,800 rows (one per municipality)
#'   and 16 columns containing census indicators. See
#'   \code{\link{gerda_census_codebook}} for variable descriptions.
#'
#' @details
#' The dataset includes:
#' \itemize{
#'   \item Demographics: Population and population shares for ages under 18,
#'         18-29, 30-49, 50-59, and 60+
#'   \item Migration: Migration background, foreign nationals
#'   \item Households: Average household size
#'   \item Housing: Dwellings, vacancy, ownership, rents, building types
#' }
#'
#' Municipality codes are 8-digit AGS codes. Since the census is a single
#' 2022 snapshot, there is no year dimension.
#'
#' The age variables follow the bins published in the Destatis Regionaltabellen.
#' In particular, `share_50to59_census22` covers ages 50-59 and
#' `share_60plus_census22` covers ages 60 and older. The source groups ages
#' 60-74 together, so it cannot support separate 50-64 and 65+ measures.
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
#' @return A data frame with 16 rows documenting all variables in the census
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
#' @param unmatched How to handle input rows whose geographic identifier does
#'   not match Census 2022. One of `"warn"` (default), `"error"`, or `"ignore"`.
#'
#' @return The input data frame with additional census columns appended. The
#'   number of rows remains unchanged. A machine-readable join report is
#'   attached and can be retrieved with [gerda_join_diagnostics()].
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
#'   \item Count variables (population_census22, total_dwellings_census22): Sums
#'   \item Other variables (avg_household_size_census22, avg_rent_per_m2_census22): Population-weighted means
#' }
#'
#' ## Validation and Diagnostics
#' Geographic identifiers must be character vectors containing exactly eight
#' digits (`ags`) or five digits (`county_code`). Numeric identifiers are
#' rejected because leading zeros may already have been lost. Before joining,
#' the function verifies reference-key uniqueness and rejects output-column
#' conflicts. It then verifies that the input row count is unchanged and
#' reports the exact number of unmatched rows and geographic units. Missing
#' join keys are classified as unexpected. Use `unmatched = "error"` in
#' unattended pipelines.
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
#'   \item \code{\link{gerda_join_diagnostics}} for inspecting match results
#' }
#'
#' @export
add_gerda_census <- function(election_data, unmatched = "warn") {
  # Avoid NOTE in R CMD check for NSE variables
  ags <- county_code <- county_code_temp <- population_census22 <- NULL

  unmatched <- validate_gerda_unmatched(unmatched)

  # Validate input
  if (!is.data.frame(election_data)) {
    stop("election_data must be a data frame")
  }

  has_ags <- "ags" %in% names(election_data)
  has_county_code <- "county_code" %in% names(election_data)

  if (!has_ags && !has_county_code) {
    stop("election_data must contain either 'ags' (for municipal-level data) or 'county_code' (for county-level data)")
  }

  identifier_name <- if (has_ags) "ags" else "county_code"
  identifier_width <- if (has_ags) 8L else 5L
  validate_gerda_identifier(
    election_data[[identifier_name]], identifier_name, identifier_width
  )

  # Get census data
  census <- gerda_census()
  validate_gerda_identifier(census$ags, "ags", 8L)
  validate_gerda_join_key(census, "ags", "GERDA Census 2022")

  # Remove municipality_name to avoid conflicts
  census_merge <- census %>%
    dplyr::select(-dplyr::any_of("municipality_name"))
  input_rows <- nrow(election_data)

  if (has_ags) {
    # Municipality-level: direct merge on AGS
    if (has_county_code) {
      message("Both 'ags' and 'county_code' found. Using 'ags' for municipality-level merge.")
    }

    assert_no_gerda_join_conflicts(
      election_data, census_merge, "ags", "add_gerda_census"
    )
    matched <- gerda_match_keys(
      election_data, census_merge, "ags", "ags"
    )
    missing_keys <- !stats::complete.cases(election_data["ags"])
    result <- election_data %>%
      dplyr::left_join(census_merge, by = "ags")
    report_keys <- "ags = ags"
    data_level <- "municipality"

  } else {
    # County-level: aggregate census to county, then merge
    message(
      "Aggregating municipality-level census data to county level.\n",
      "Share variables are population-weighted means; counts are sums."
    )

    # Identify share vs count columns
    share_cols <- grep("^share_|^avg_|vacancy_rate", names(census_merge), value = TRUE)
    count_cols <- c("population_census22", "total_dwellings_census22")

    # Aggregate to county level
    census_county <- census_merge %>%
      dplyr::mutate(county_code_temp = substr(ags, 1, 5)) %>%
      dplyr::group_by(county_code_temp) %>%
      dplyr::summarize(
        dplyr::across(
          dplyr::all_of(share_cols),
          ~ stats::weighted.mean(.x, w = population_census22, na.rm = TRUE),
          .names = "{.col}"
        ),
        dplyr::across(
          dplyr::all_of(count_cols),
          ~ sum(.x, na.rm = TRUE),
          .names = "{.col}"
        ),
        .groups = "drop"
      ) %>%
      dplyr::rename(county_code = county_code_temp)

    validate_gerda_identifier(census_county$county_code, "county_code", 5L)
    validate_gerda_join_key(
      census_county, "county_code", "County-aggregated GERDA Census 2022"
    )
    assert_no_gerda_join_conflicts(
      election_data, census_county, "county_code", "add_gerda_census"
    )
    matched <- gerda_match_keys(
      election_data, census_county, "county_code", "county_code"
    )
    missing_keys <- !stats::complete.cases(election_data["county_code"])

    result <- election_data %>%
      dplyr::left_join(census_county, by = "county_code")
    report_keys <- "county_code = county_code"
    data_level <- "county"
  }

  assert_gerda_row_count(input_rows, nrow(result), "add_gerda_census")
  outside_coverage <- rep(FALSE, input_rows)
  report <- make_gerda_join_report(
    helper = "add_gerda_census",
    data_level = data_level,
    identifier_name = identifier_name,
    identifier = election_data[[identifier_name]],
    join_keys = report_keys,
    matched = matched,
    outside_coverage = outside_coverage,
    missing_keys = missing_keys,
    output_rows = nrow(result),
    unmatched_action = unmatched
  )
  result <- attach_gerda_join_report(result, election_data, report)
  signal_gerda_join_report(report)

  return(result)
}
