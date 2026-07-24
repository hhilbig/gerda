#' Load GERDA Data
#'
#' This function loads GERDA data from a web source.
#'
#' @param file_name A character string specifying the name of the file to load. For a list of available data, see \code{\link{gerda_data_list}}.
#' @param verbose A logical value indicating whether to print additional messages to the console. Default is FALSE.
#' @param file_format A character string specifying the format of the file. Must be either "csv" or "rds". Default is "rds".
#' @param on_error How to handle errors (unknown dataset name, failed download, corrupt file, invalid `file_format`). Either `"warn"` (default) to emit a warning and return `NULL`, or `"stop"` to raise an error. Use `"stop"` inside scripts or pipelines where silent `NULL` returns would produce confusing downstream failures. The global default can also be overridden with `options(gerda.on_error = "stop")`.
#' @param timeout Download timeout in seconds. Defaults to `getOption("gerda.timeout", 300)`. The value is applied only for the duration of the download (raising R's default of 60s, which is too short for the larger GERDA files) and restored afterwards.
#' @param max_retries Number of additional download attempts after the first, with exponential backoff, if a download fails or returns a Git LFS pointer instead of data. Defaults to `getOption("gerda.max_retries", 2)` (so up to three attempts in total).
#' @param cache Logical; if `TRUE`, downloaded datasets are cached on disk (in `gerda_cache_dir()`) and reused on subsequent calls instead of being re-downloaded. Defaults to `getOption("gerda.cache", FALSE)`. Caching is opt-in so the package never writes to user filespace without consent. See [clear_gerda_cache()] to purge the cache.
#' @param refresh Logical; if `TRUE`, ignore any cached copy and force a fresh download (updating the cache when `cache = TRUE`). Default is `FALSE`.
#'
#' @section Vote-share columns:
#' Election datasets expose one column per party (e.g. `cdu`, `spd`, `gruene`, `afd`).
#' These columns hold the party's share of valid votes and are expressed as
#' fractions of 1. They do **not** sum to 1 across the named major parties:
#' the remainder is held by smaller parties with their own columns and, at
#' the tail, an `other` category. For example, in `federal_cty_harm` for 2021,
#' `cdu + csu + spd + gruene + fdp + linke_pds + afd` is typically around
#' 0.91 and ranges roughly 0.78 to 0.97 across counties. To reconstruct a
#' full 1.0 share, include every party column or use `other` together with
#' turnout and invalid-vote columns.
#'
#' @return A tibble containing the loaded data, or NULL if the data could not be loaded.
#'
#' @seealso [gerda_data_list()] for the dataset catalog, [clear_gerda_cache()]
#'   and [gerda_cache_dir()] for cache management.
#'
#' @examples
#' \donttest{
#' # Load harmonized municipal elections data
#' data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")
#'
#' # Load federal election data harmonized to 2025 boundaries (includes 2025 election)
#' data_federal_2025 <- load_gerda_web("federal_muni_harm_25", verbose = TRUE, file_format = "rds")
#'
#' # Cache the download so repeated calls in the same project reuse it
#' data_federal_2025 <- load_gerda_web("federal_muni_harm_25", cache = TRUE)
#' }
#'
#' @import dplyr
#' @import stringdist
#' @import readr
#' @export

load_gerda_web <- function(file_name,
                           verbose = FALSE,
                           file_format = "rds",
                           on_error = getOption("gerda.on_error", "warn"),
                           timeout = getOption("gerda.timeout", 300),
                           max_retries = getOption("gerda.max_retries", 2),
                           cache = getOption("gerda.cache", FALSE),
                           refresh = FALSE) {
    if (!is.character(file_name) || length(file_name) != 1 || nchar(file_name) == 0) {
        stop("file_name must be a single non-empty character string")
    }

    if (!is.character(on_error) || length(on_error) != 1 || !on_error %in% c("warn", "stop")) {
        stop("on_error must be either \"warn\" or \"stop\"")
    }

    if (!is.numeric(timeout) || length(timeout) != 1 || is.na(timeout) || timeout <= 0) {
        stop("timeout must be a single positive number (seconds)")
    }

    if (!is.numeric(max_retries) || length(max_retries) != 1 || is.na(max_retries) || max_retries < 0) {
        stop("max_retries must be a single non-negative number")
    }

    if (!is.logical(cache) || length(cache) != 1 || is.na(cache)) {
        stop("cache must be a single logical value (TRUE or FALSE)")
    }

    if (!is.logical(refresh) || length(refresh) != 1 || is.na(refresh)) {
        stop("refresh must be a single logical value (TRUE or FALSE)")
    }

    # Internal helper: every failure path goes through this so the on_error
    # contract is consistent (warn + NULL, or stop).
    fail <- function(msg) {
        if (on_error == "stop") {
            stop(msg, call. = FALSE)
        } else {
            warning(msg, call. = FALSE)
            return(invisible(NULL))
        }
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

    # Build the data dictionary from the single source of truth (gerda_catalog()),
    # deriving the download URLs from each dataset's repository path.
    base_url <- "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/"
    catalog <- gerda_catalog()
    data_dictionary <- data.frame(
        data_name   = catalog$data_name,
        description = catalog$description,
        csv_url     = paste0(base_url, catalog$path, ".csv?download="),
        rds_url     = paste0(base_url, catalog$path, ".rds"),
        formats     = catalog$formats,
        stringsAsFactors = FALSE
    )

    # Check if file_name is in data_dict

    if (!file_name %in% data_dictionary$data_name) {
        # Special handling for deprecated federal_muni_harm dataset
        if (file_name == "federal_muni_harm") {
            return(fail(paste0(
                "The dataset 'federal_muni_harm' has been replaced with two boundary-specific versions:\n",
                "  - 'federal_muni_harm_21': harmonized to 2021 boundaries\n",
                "  - 'federal_muni_harm_25': harmonized to 2025 boundaries\n",
                "Please replace 'federal_muni_harm' in your function call with one of these datasets,\n",
                "depending on which boundary harmonization you need.\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )))
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

        if (length(close_matches) > 1) {
            return(fail(paste0(
                "File name not found in data dictionary.\nDid you mean: \"",
                close_matches[1], "\" or \"", close_matches[2], "\"?\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )))
        } else if (length(close_matches) == 1) {
            return(fail(paste0(
                "File name not found in data dictionary.\nDid you mean: \"",
                close_matches[1], "\"?\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )))
        } else {
            return(fail(paste0(
                "File name not found in data dictionary.\n",
                "For a complete list of available datasets, see gerda_data_list()."
            )))
        }
    }

    if (verbose) {
        message("File name found in data dictionary")
    }

    # Check if file_format is valid
    if (!file_format %in% c("csv", "rds")) {
        return(fail("Invalid file_format. Must be either 'csv' or 'rds'."))
    }

    # Some datasets (e.g. the targeted 2023/2024 -> 2025 crosswalks) ship in RDS
    # only. Fail informatively instead of letting the user hit a 404.
    available_formats <- strsplit(
        data_dictionary$formats[data_dictionary$data_name == file_name], ","
    )[[1]]
    if (!file_format %in% available_formats) {
        return(fail(paste0(
            "Dataset '", file_name, "' is not available in '", file_format,
            "' format. Available format(s): ",
            paste(available_formats, collapse = ", "),
            ". Use file_format = \"", available_formats[1], "\"."
        )))
    }

    # Get the url
    url <- data_dictionary[[paste0(file_format, "_url")]][data_dictionary$data_name == file_name]

    if (verbose) {
        message("URL found: ", url)
        message("Loading data...")
    }

    # Read a local file (cached copy or freshly downloaded tempfile). Reading
    # from disk lets base `readRDS` auto-detect any R-supported compression
    # (e.g. the xz-compressed 1990->2025 crosswalks), which streaming
    # `readr::read_rds` from a URL could not, and keeps CSV behavior symmetrical.
    read_local <- function(path) {
        switch(file_format,
            "csv" = read_csv(path, show_col_types = FALSE),
            "rds" = readRDS(path)
        )
    }

    use_cache <- isTRUE(cache)
    cache_file <- if (use_cache) {
        file.path(gerda_cache_dir(), paste0(file_name, ".", file_format))
    } else {
        NULL
    }

    data <- NULL

    # Fast path: read a valid cached copy without touching the network.
    if (use_cache && !refresh && file.exists(cache_file) && !is_lfs_pointer(cache_file)) {
        if (verbose) {
            message("Reading from cache: ", cache_file)
        }
        data <- tryCatch(read_local(cache_file), error = function(e) {
            if (verbose) {
                message("Cached file unreadable; re-downloading. (",
                        conditionMessage(e), ")")
            }
            NULL
        })
    }

    # Download path: fetch to a tempfile (with timeout + retries + LFS check),
    # read it, and populate the cache on success.
    if (is.null(data)) {
        tmp <- tempfile(fileext = paste0(".", file_format))
        on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)

        status <- fetch_to_file(url, tmp,
            timeout = timeout, max_retries = max_retries, verbose = verbose
        )
        if (!status$success) {
            return(fail(paste0(
                "Error loading data: ", status$message,
                "\nThe data may not be available or may have changed. ",
                "Please contact the package maintainer."
            )))
        }

        data <- tryCatch(read_local(tmp), error = function(e) {
            fail(paste0(
                "Error loading data: ", conditionMessage(e),
                "\nThe data may not be available or may have changed. ",
                "Please contact the package maintainer."
            ))
        })
        if (is.null(data)) {
            return(invisible(NULL))
        }

        if (use_cache) {
            cdir <- dirname(cache_file)
            if (!dir.exists(cdir)) {
                dir.create(cdir, recursive = TRUE, showWarnings = FALSE)
            }
            copied <- tryCatch(
                file.copy(tmp, cache_file, overwrite = TRUE),
                error = function(e) FALSE
            )
            if (verbose && isTRUE(copied)) {
                message("Cached to: ", cache_file)
            }
        }
    }

    # Normalize schema for known upstream inconsistencies.
    # federal_cty_unharm ships with 'ags' (a 5-digit county code) and 'year',
    # while all other county-level datasets use 'county_code' and 'election_year'.
    # Since v0.8 the upstream columns are renamed on load; the deprecated
    # 'ags'/'year' duplicates (announced for removal in 0.6.0) are gone.
    if (!is.null(data) && file_name == "federal_cty_unharm") {
        renamed <- FALSE
        if ("ags" %in% names(data) && !"county_code" %in% names(data)) {
            names(data)[names(data) == "ags"] <- "county_code"
            renamed <- TRUE
        }
        if ("year" %in% names(data) && !"election_year" %in% names(data)) {
            names(data)[names(data) == "year"] <- "election_year"
            renamed <- TRUE
        }
        if (renamed) {
            message(
                "Note: the upstream 'ags' and 'year' columns of 'federal_cty_unharm' are ",
                "provided as 'county_code' and 'election_year' to match the other ",
                "county-level datasets. The deprecated 'ags'/'year' duplicates were ",
                "removed in v0.8."
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
