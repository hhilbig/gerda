#' List of GERDA Data
#'
#' This function lists the available GERDA data sets. The purpose of this
#' function is to quickly provide a list of available data sets and their
#' descriptions.
#'
#' In addition to downloadable datasets, the package includes bundled
#' covariate data accessible via dedicated functions:
#' \itemize{
#'   \item \code{\link{gerda_covariates}}: County-level INKAR covariates (1995-2022)
#'   \item \code{\link{gerda_census}}: Municipality-level Census 2022 data
#' }
#'
#' @return A tibble containing the available GERDA data with descriptions. When print_table = TRUE,
#'         the function prints a formatted table to the console and invisibly returns the data tibble.
#'         When print_table = FALSE, the function directly returns the data tibble.
#' @param print_table A logical value indicating whether to print the table in the console (TRUE) or return the data as a tibble (FALSE). Default is TRUE.
#'
#' @examples
#' gerda_data_list()
#'
#' @export
#'
gerda_data_list <- function(print_table = TRUE) {
    if (!isTRUE(print_table) && !isFALSE(print_table)) {
        stop("print_table must be TRUE or FALSE")
    }

    data <- tibble::tribble(
        ~data_name, ~description,
        "municipal_unharm", "Local elections at the municipal level (1990-2020, unharmonized).",
        "municipal_harm", "Local elections at the municipal level (1990-2020, harmonized).",
        "municipal_harm_25", "Local elections at the municipal level, harmonized to 2025 boundaries.",
        "state_unharm", "State elections at the municipal level (2006-2019, unharmonized).",
        "state_harm", "State elections at the municipal level (2006-2019, harmonized).",
        "state_harm_21", "State elections at the municipal level, harmonized to 2021 boundaries.",
        "state_harm_23", "State elections at the municipal level, harmonized to 2023 boundaries.",
        "state_harm_25", "State elections at the municipal level, harmonized to 2025 boundaries.",
        "federal_muni_raw", "Federal elections at the municipal level (1980-2025, raw data).",
        "federal_muni_unharm", "Federal elections at the municipal level (1980-2025, unharmonized).",
        "federal_muni_harm_21", "Federal elections at the municipal level (1990-2025, harmonized to 2021 boundaries).",
        "federal_muni_harm_25", "Federal elections at the municipal level (1990-2025, harmonized to 2025 boundaries).",
        "federal_cty_unharm", "Federal elections at the county level (1953-2021, unharmonized).",
        "federal_cty_harm", "Federal elections at the county level (1990-2021, harmonized).",
        "county_elec_unharm", "County (Kreistag) elections at the municipal level, unharmonized.",
        "county_elec_harm_21", "County (Kreistag) elections, harmonized to 2021 boundaries.",
        "county_elec_harm_21_cty", "County (Kreistag) elections aggregated to county level, harmonized to 2021 boundaries.",
        "county_elec_harm_21_muni", "County (Kreistag) elections at the municipal level, harmonized to 2021 boundaries.",
        "european_muni_unharm", "European Parliament elections at the municipal level, unharmonized.",
        "european_muni_harm", "European Parliament elections at the municipal level, harmonized.",
        "mayoral_unharm", "Mayoral election results at the municipal level, unharmonized.",
        "mayoral_harm", "Mayoral election results at the municipal level, harmonized.",
        "mayoral_candidates", "Mayoral candidates (person-level).",
        "mayor_panel", "Mayor panel (person-level, one row per mayor-term).",
        "mayor_panel_harm", "Mayor panel (person-level, harmonized to current boundaries).",
        "mayor_panel_annual", "Mayor panel at annual frequency (one row per municipality-year).",
        "mayor_panel_annual_harm", "Mayor panel at annual frequency, harmonized to current boundaries.",
        "ags_crosswalks", "Crosswalks for municipalities (1990-2025).",
        "cty_crosswalks", "Crosswalks for counties (1990-2025).",
        "ags_1990_to_2023_crosswalk", "Municipality crosswalk: 1990 boundaries to 2023 boundaries.",
        "ags_1990_to_2025_crosswalk", "Municipality crosswalk: 1990 boundaries to 2025 boundaries.",
        "crosswalk_ags_2021_to_2023", "Municipality crosswalk: AGS 2021 to AGS 2023 (targeted).",
        "crosswalk_ags_2021_2022_to_2023", "Municipality crosswalk: AGS 2021 and 2022 to AGS 2023 (targeted).",
        "crosswalk_ags_2023_to_2025", "Municipality crosswalk: AGS 2023 to AGS 2025 (targeted; RDS only).",
        "crosswalk_ags_2023_24_to_2025", "Municipality crosswalk: AGS 2023 and 2024 to AGS 2025 (targeted; RDS only).",
        "crosswalk_ags_2024_to_2025", "Municipality crosswalk: AGS 2024 to AGS 2025 (targeted; RDS only).",
        "ags_area_pop_emp", "Crosswalk covariates (area, population, employment) for municipalities (1990-2025).",
        "ags_area_pop_emp_2023", "Crosswalk covariates (area, population, employment) for municipalities, harmonized to 2023 boundaries.",
        "cty_area_pop_emp", "Crosswalk covariates (area, population, employment) for counties (1990-2025)."
    )

    if (!print_table) {
        return(data)
    } else {
        # Print one dataset per line as "name  description" so long descriptions
        # are never truncated (the previous kable-based output wrapped or
        # elided, making pairs like federal_muni_harm_21 / _25 indistinguishable
        # by description in narrow terminals).
        name_width <- max(nchar(data$data_name)) + 2L
        for (i in seq_len(nrow(data))) {
            cat(format(data$data_name[i], width = name_width),
                data$description[i], "\n", sep = "")
        }
        invisible(data)
    }
}
