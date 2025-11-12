#' List of GERDA Data
#'
#' This function lists the available GERDA data sets. The purpose of this function is to quickly provide a list of available data sets and their descriptions.
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
    data <- tibble::tribble(
        ~data_name, ~description,
        "municipal_unharm", "Local elections at the municipal level (1990-2020, unharmonized).",
        "municipal_harm", "Local elections at the municipal level (1990-2020, harmonized).",
        "state_unharm", "State elections at the municipal level (2006-2019, unharmonized).",
        "state_harm", "State elections at the municipal level (2006-2019, harmonized).",
        "federal_muni_raw", "Federal elections at the municipal level (1980-2025, raw data).",
        "federal_muni_unharm", "Federal elections at the municipal level (1980-2025, unharmonized).",
        "federal_muni_harm_21", "Federal elections at the municipal level (1990-2025, harmonized to 2021 boundaries).",
        "federal_muni_harm_25", "Federal elections at the municipal level (1990-2025, harmonized to 2025 boundaries).",
        "federal_cty_unharm", "Federal elections at the county level (1953-2021, unharmonized).",
        "federal_cty_harm", "Federal elections at the county level (1990-2021, harmonized).",
        "ags_crosswalks", "Crosswalks for municipalities (1990-2025).",
        "cty_crosswalks", "Crosswalks for counties (1990-2025).",
        "ags_area_pop_emp", "Crosswalk covariates (area, population, employment) for municipalities (1990-2025).",
        "cty_area_pop_emp", "Crosswalk covariates (area, population, employment) for counties (1990-2025)."
    )

    if (!print_table) {
        return(data)
    } else {
        # Format the table for nice display in the terminal
        formatted_table <- knitr::kable(data, format = "pipe", align = c("l", "l"))
        # Print the formatted table
        cat(formatted_table, sep = "\n")
        invisible(data)
    }
}
