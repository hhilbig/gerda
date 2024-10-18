#' List of GERDA Data
#'
#' This function lists the available GERDA data sets.
#'
#' @return A tibble listing the available GERDA data with descriptions.
#'
#' @examples
#' gerda_data_list()
#'
#' @export
#'
gerda_data_list <- function() {
    structure(list(data_name = c(
        "municipal_unharm", "municipal_harm",
        "state_unharm", "state_harm", "federal_muni_raw", "federal_muni_unharm",
        "federal_muni_harm", "federal_cty_unharm", "federal_cty_harm",
        "ags_crosswalks", "cty_crosswalks", "ags_area_pop_emp", "cty_area_pop_emp"
    ), description = c(
        "Local elections at the municipal level (1990–2020, unharmonized).",
        "Local elections at the municipal level (1990–2020, harmonized).",
        "State elections at the municipal level (2006–2019, unharmonized).",
        "State elections at the municipal level (2006–2019, harmonized).",
        "Federal elections at the municipal level (1980–2021, raw data).",
        "Federal elections at the municipal level (1980–2021, unharmonized).",
        "Federal elections at the municipal level (1990–2021, harmonized).",
        "Federal elections at the county level (1953–2021, unharmonized).",
        "Federal elections at the county level (1990–2021, harmonized).",
        "Crosswalks for municipalities (1990–2021).", "Crosswalks for counties (1990–2021).",
        "Crosswalk covariates (area, population, employment) for municipalities (1990–2021).",
        "Crosswalk covariates (area, population, employment) for counties (1990–2021)."
    ), csv_url = c(
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_raw.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/ags_crosswalks.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/cty_crosswalks.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_municipality/final/ags_area_pop_emp.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_county/final/cty_area_pop_emp.csv?download="
    )), class = "data.frame", row.names = c(NA, -13L)) %>%
        dplyr::select(data_name, description)
}
