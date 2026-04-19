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
#' # Load harmonized municipal elections data
#' data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")
#'
#' # Load federal election data harmonized to 2025 boundaries (includes 2025 election)
#' data_federal_2025 <- load_gerda_web("federal_muni_harm_25", verbose = TRUE, file_format = "rds")
#' }
#'
#' @import dplyr
#' @import stringdist
#' @import readr
#' @export

load_gerda_web <- function(file_name, verbose = FALSE, file_format = "rds") {
    if (!is.character(file_name) || length(file_name) != 1 || nchar(file_name) == 0) {
        stop("file_name must be a single non-empty character string")
    }

    # Check if file_name ends with .rds or .csv and handle accordingly
    if (nchar(file_name) > 4) {
        last_4_chars <- substr(file_name, nchar(file_name) - 3, nchar(file_name))
        if (last_4_chars %in% c(".rds", ".csv")) {
            file_name <- substr(file_name, 1, nchar(file_name) - 4)
            message(
                "File extension (.rds or .csv) not required - adding it is optional."
            )
        }
    }

    # Load data dict
    base_url <- "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/"
    make_csv <- function(path) paste0(base_url, path, ".csv?download=")
    make_rds <- function(path) paste0(base_url, path, ".rds")

    entries <- list(
        # Original 14 datasets
        list("municipal_unharm",
             "Local elections at the municipal level (1990-2020, unharmonized).",
             "municipal_elections/final/municipal_unharm"),
        list("municipal_harm",
             "Local elections at the municipal level (1990-2020, harmonized).",
             "municipal_elections/final/municipal_harm"),
        list("state_unharm",
             "State elections at the municipal level (2006-2019, unharmonized).",
             "state_elections/final/state_unharm"),
        list("state_harm",
             "State elections at the municipal level (2006-2019, harmonized).",
             "state_elections/final/state_harm"),
        list("federal_muni_raw",
             "Federal elections at the municipal level (1980-2025, raw data).",
             "federal_elections/municipality_level/final/federal_muni_raw"),
        list("federal_muni_unharm",
             "Federal elections at the municipal level (1980-2025, unharmonized).",
             "federal_elections/municipality_level/final/federal_muni_unharm"),
        list("federal_muni_harm_21",
             "Federal elections at the municipal level (1990-2025, harmonized to 2021 boundaries).",
             "federal_elections/municipality_level/final/federal_muni_harm_21"),
        list("federal_muni_harm_25",
             "Federal elections at the municipal level (1990-2025, harmonized to 2025 boundaries).",
             "federal_elections/municipality_level/final/federal_muni_harm_25"),
        list("federal_cty_unharm",
             "Federal elections at the county level (1953-2021, unharmonized).",
             "federal_elections/county_level/final/federal_cty_unharm"),
        list("federal_cty_harm",
             "Federal elections at the county level (1990-2021, harmonized).",
             "federal_elections/county_level/final/federal_cty_harm"),
        list("ags_crosswalks",
             "Crosswalks for municipalities (1990-2025).",
             "crosswalks/final/ags_crosswalks"),
        list("cty_crosswalks",
             "Crosswalks for counties (1990-2025).",
             "crosswalks/final/cty_crosswalks"),
        list("ags_area_pop_emp",
             "Crosswalk covariates (area, population, employment) for municipalities (1990-2025).",
             "covars_municipality/final/ags_area_pop_emp"),
        list("cty_area_pop_emp",
             "Crosswalk covariates (area, population, employment) for counties (1990-2025).",
             "covars_county/final/cty_area_pop_emp"),

        # County (Kreistag) elections
        list("county_elec_unharm",
             "County (Kreistag) elections at the municipal level, unharmonized.",
             "county_elections/final/county_elec_unharm"),
        list("county_elec_harm_21",
             "County (Kreistag) elections, harmonized to 2021 boundaries.",
             "county_elections/final/county_elec_harm_21"),
        list("county_elec_harm_21_cty",
             "County (Kreistag) elections aggregated to county level, harmonized to 2021 boundaries.",
             "county_elections/final/county_elec_harm_21_cty"),
        list("county_elec_harm_21_muni",
             "County (Kreistag) elections at the municipal level, harmonized to 2021 boundaries.",
             "county_elections/final/county_elec_harm_21_muni"),

        # European Parliament elections
        list("european_muni_unharm",
             "European Parliament elections at the municipal level, unharmonized.",
             "european_elections/final/european_muni_unharm"),
        list("european_muni_harm",
             "European Parliament elections at the municipal level, harmonized.",
             "european_elections/final/european_muni_harm"),

        # Mayoral elections
        list("mayoral_unharm",
             "Mayoral election results at the municipal level, unharmonized.",
             "mayoral_elections/final/mayoral_unharm"),
        list("mayoral_harm",
             "Mayoral election results at the municipal level, harmonized.",
             "mayoral_elections/final/mayoral_harm"),
        list("mayoral_candidates",
             "Mayoral candidates (person-level).",
             "mayoral_elections/final/mayoral_candidates"),
        list("mayor_panel",
             "Mayor panel (person-level, one row per mayor-term).",
             "mayoral_elections/final/mayor_panel"),
        list("mayor_panel_harm",
             "Mayor panel (person-level, harmonized to current boundaries).",
             "mayoral_elections/final/mayor_panel_harm"),
        list("mayor_panel_annual",
             "Mayor panel at annual frequency (one row per municipality-year).",
             "mayoral_elections/final/mayor_panel_annual"),
        list("mayor_panel_annual_harm",
             "Mayor panel at annual frequency, harmonized to current boundaries.",
             "mayoral_elections/final/mayor_panel_annual_harm"),

        # Boundary-specific harmonizations
        list("municipal_harm_25",
             "Local elections at the municipal level, harmonized to 2025 boundaries.",
             "municipal_elections/final/municipal_harm_25"),
        list("state_harm_21",
             "State elections at the municipal level, harmonized to 2021 boundaries.",
             "state_elections/final/state_harm_21"),
        list("state_harm_23",
             "State elections at the municipal level, harmonized to 2023 boundaries.",
             "state_elections/final/state_harm_23"),
        list("state_harm_25",
             "State elections at the municipal level, harmonized to 2025 boundaries.",
             "state_elections/final/state_harm_25"),

        # Additional crosswalks
        list("ags_1990_to_2023_crosswalk",
             "Municipality crosswalk: 1990 boundaries to 2023 boundaries.",
             "crosswalks/final/ags_1990_to_2023_crosswalk"),
        list("ags_1990_to_2025_crosswalk",
             "Municipality crosswalk: 1990 boundaries to 2025 boundaries.",
             "crosswalks/final/ags_1990_to_2025_crosswalk"),
        list("crosswalk_ags_2021_to_2023",
             "Municipality crosswalk: AGS 2021 to AGS 2023 (targeted).",
             "crosswalks/final/crosswalk_ags_2021_to_2023"),
        list("crosswalk_ags_2021_2022_to_2023",
             "Municipality crosswalk: AGS 2021 and 2022 to AGS 2023 (targeted).",
             "crosswalks/final/crosswalk_ags_2021_2022_to_2023"),
        list("crosswalk_ags_2023_to_2025",
             "Municipality crosswalk: AGS 2023 to AGS 2025 (targeted; RDS only).",
             "crosswalks/final/crosswalk_ags_2023_to_2025"),
        list("crosswalk_ags_2023_24_to_2025",
             "Municipality crosswalk: AGS 2023 and 2024 to AGS 2025 (targeted; RDS only).",
             "crosswalks/final/crosswalk_ags_2023_24_to_2025"),
        list("crosswalk_ags_2024_to_2025",
             "Municipality crosswalk: AGS 2024 to AGS 2025 (targeted; RDS only).",
             "crosswalks/final/crosswalk_ags_2024_to_2025"),

        # Alternative-boundary covariates
        list("ags_area_pop_emp_2023",
             "Crosswalk covariates (area, population, employment) for municipalities, harmonized to 2023 boundaries.",
             "covars_municipality/final/ags_area_pop_emp_2023")
    )

    data_dictionary <- data.frame(
        data_name   = vapply(entries, `[[`, character(1), 1),
        description = vapply(entries, `[[`, character(1), 2),
        csv_url     = vapply(entries, function(e) make_csv(e[[3]]), character(1)),
        rds_url     = vapply(entries, function(e) make_rds(e[[3]]), character(1)),
        stringsAsFactors = FALSE
    )


    # Check if file_name is in data_dict

    if (!file_name %in% data_dictionary$data_name) {
        # Special handling for deprecated federal_muni_harm dataset
        if (file_name == "federal_muni_harm") {
            warning(
                "The dataset 'federal_muni_harm' has been replaced with two boundary-specific versions:\n",
                "  - 'federal_muni_harm_21': harmonized to 2021 boundaries\n",
                "  - 'federal_muni_harm_25': harmonized to 2025 boundaries\n",
                "Please replace 'federal_muni_harm' in your function call with one of these datasets,\n",
                "depending on which boundary harmonization you need.\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )
            return(NULL)
        }

        # Check if there is a close match in data_dict$data_name
        close_matches <- agrep(file_name,
            data_dictionary$data_name,
            max.distance = 0.5, value = TRUE
        )

        if (length(close_matches) > 0) {
            # Prioritize matches that start with the same prefix
            starts_with_prefix <- startsWith(close_matches, file_name)
            if (any(starts_with_prefix)) {
                close_matches <- c(
                    close_matches[starts_with_prefix],
                    close_matches[!starts_with_prefix]
                )
            } else {
                # If no prefix match, use Levenshtein distance
                distances <- stringdist::stringdist(file_name,
                    close_matches,
                    method = "lv"
                )
                close_matches <- close_matches[order(distances)]
            }
        }

        if (length(close_matches) > 0) {
            if (length(close_matches) > 1) {
                warning(
                    "File name not found in data dictionary.\nDid you mean: \"",
                    close_matches[1], "\" or \"", close_matches[2], "\"?\n",
                    "For a complete list of available datasets, see gerda_data_list()."
                )
            } else {
                warning(
                    "File name not found in data dictionary.\nDid you mean: \"",
                    close_matches[1], "\"?\n",
                    "For a complete list of available datasets, see gerda_data_list()."
                )
            }
        } else {
            warning(
                "File name not found in data dictionary.\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )
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
    url <- data_dictionary[[paste0(file_format, "_url")]][data_dictionary$data_name == file_name]

    if (verbose) {
        message("URL found: ", url)
        message("Loading data...")
    }

    # Download to a tempfile first, then read locally. Streaming `readr::read_rds`
    # directly from a URL breaks on xz-compressed RDS files (e.g. the 1990->2025
    # crosswalks), because the streaming reader doesn't auto-detect xz. Reading
    # from disk lets base `readRDS` auto-detect any R-supported compression, and
    # keeps CSV behavior symmetrical.
    #
    # Raise the download timeout for the duration of the fetch. R's default
    # (60s) is too short for some of the larger GERDA files over GitHub-media
    # on slower connections; users otherwise see sporadic timeouts on the first
    # pull of files like mayor_panel_annual_harm or federal_muni_harm_21.
    old_timeout <- getOption("timeout")
    if (is.null(old_timeout) || old_timeout < 300) {
        options(timeout = 300)
        on.exit(options(timeout = old_timeout), add = TRUE)
    }
    tmp <- tempfile(fileext = paste0(".", file_format))
    on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
    data <- tryCatch(
        {
            utils::download.file(url, tmp, mode = "wb", quiet = !verbose)
            switch(file_format,
                "csv" = read_csv(tmp, show_col_types = FALSE),
                "rds" = readRDS(tmp)
            )
        },
        error = function(e) {
            warning("Error loading data: ", e$message, "\nThe data may not be available or may have changed. Please contact the package maintainer.")
            return(NULL)
        }
    )

    # Normalize schema for known upstream inconsistencies.
    # federal_cty_unharm ships with 'ags' (a 5-digit county code) and 'year',
    # while all other county-level datasets use 'county_code' and 'election_year'.
    # To keep downstream helpers like add_gerda_covariates() working without
    # breaking existing user code, add 'county_code'/'election_year' as aliases
    # alongside the original columns. The 'ags' and 'year' aliases are
    # deprecated and scheduled for removal in v0.7.
    if (!is.null(data) && file_name == "federal_cty_unharm") {
        added_alias <- FALSE
        if ("ags" %in% names(data) && !"county_code" %in% names(data)) {
            data$county_code <- data$ags
            added_alias <- TRUE
        }
        if ("year" %in% names(data) && !"election_year" %in% names(data)) {
            data$election_year <- data$year
            added_alias <- TRUE
        }
        if (added_alias) {
            message(
                "Note: 'federal_cty_unharm' now also provides 'county_code' and 'election_year' ",
                "to match other county-level datasets. The upstream 'ags' and 'year' columns ",
                "remain for backwards compatibility but are deprecated and will be removed in v0.7. ",
                "Please migrate your code to the new column names."
            )
        }
    }

    if (verbose) {
        if (!is.null(data)) {
            message("Data loaded successfully")
        } else {
            message("Data loading failed. See warnings for details.")
        }
    }

    return(data)
}
