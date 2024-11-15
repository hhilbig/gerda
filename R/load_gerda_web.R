#' Load GERDA Data
#'
#' This function loads GERDA data from a web source.
#'
#' @param file_name A character string specifying the name of the file to load. For a list of available data, see \code{\link{gerda_data_list}}.
#' @param verbose A logical value indicating whether to print additional messages to the console. Default is FALSE.
#' @param file_format A character string specifying the format of the file. Must be either "csv" or "rds". Default is "rds".
#'
#' @return A tibble containing the loaded data, or NULL if the data could not be loaded.
#'
#' @examples
#' \donttest{
#' data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")
#' }
#'
#' @import dplyr
#' @import stringdist
#' @import readr
#' @export

load_gerda_web <- function(file_name, verbose = FALSE, file_format = "rds") {
    # Load data dict
    data_dictionary <- data.frame(
        data_name = c(
            "municipal_unharm", "municipal_harm", "state_unharm", "state_harm",
            "federal_muni_raw", "federal_muni_unharm", "federal_muni_harm",
            "federal_cty_unharm", "federal_cty_harm", "ags_crosswalks",
            "cty_crosswalks", "ags_area_pop_emp", "cty_area_pop_emp"
        ),
        description = c(
            "Local elections at the municipal level (1990-2020, unharmonized).",
            "Local elections at the municipal level (1990-2020, harmonized).",
            "State elections at the municipal level (2006-2019, unharmonized).",
            "State elections at the municipal level (2006-2019, harmonized).",
            "Federal elections at the municipal level (1980-2021, raw data).",
            "Federal elections at the municipal level (1980-2021, unharmonized).",
            "Federal elections at the municipal level (1990-2021, harmonized).",
            "Federal elections at the county level (1953-2021, unharmonized).",
            "Federal elections at the county level (1990-2021, harmonized).",
            "Crosswalks for municipalities (1990-2021).",
            "Crosswalks for counties (1990-2021).",
            "Crosswalk covariates (area, population, employment) for municipalities (1990-2021).",
            "Crosswalk covariates (area, population, employment) for counties (1990-2021)."
        ),
        csv_url = c(
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
        ),
        rds_url = c(
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_unharm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_harm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_unharm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_harm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_raw.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_unharm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_harm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_unharm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_harm.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/ags_crosswalks.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/cty_crosswalks.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_municipality/final/ags_area_pop_emp.rds",
            "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_county/final/cty_area_pop_emp.rds"
        )
    )


    # Check if file_name is in data_dict

    if (!file_name %in% data_dictionary$data_name) {
        # Check if there is a close match in data_dict$data_name

        close_matches <- agrep(file_name,
            data_dictionary$data_name,
            max.distance = 0.5, value = TRUE
        )

        if (length(close_matches) > 0) {
            distances <- stringdist::stringdist(file_name,
                close_matches,
                method = "lv"
            )
            close_matches <- close_matches[order(distances)]
        }

        if (length(close_matches) > 0) {
            warning(
                "File name not found in data dictionary.\nDid you mean: \"",
                close_matches[1], "\"?"
            )
        } else {
            warning("File name not found in data dictionary")
        }
        return(NULL)
    }

    if (verbose) {
        message("File name found in data dictionary")
    }

    # Check if file_format is valid
    if (!file_format %in% c("csv", "rds")) {
        warning("Invalid file_format. Must be either 'csv' or 'rds'.")
        return(NULL)
    }

    # Get the url
    url <- data_dictionary %>%
        dplyr::filter(.data$data_name == file_name) %>%
        dplyr::pull(!!sym(paste0(file_format, "_url")))

    if (verbose) {
        message("URL found: ", url)
        message("Loading data...")
    }

    # Load the data based on the file format
    data <- tryCatch(
        {
            switch(file_format,
                "csv" = read_csv(url),
                "rds" = read_rds(url)
            )
        },
        error = function(e) {
            warning("Error loading data: ", e$message, "\nThe data may not be available or may have changed. Please contact the package maintainer.")
            return(NULL)
        }
    )

    if (verbose && !is.null(data)) {
        message("Data loaded successfully")
    }

    return(data)
}
