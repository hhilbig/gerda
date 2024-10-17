#' Load GERDA Data
#'
#' This function loads GERDA data .
#'
#' @param file_name A character string specifying the name of the file to load. For a list of available data, see \code{\link{gerda_data_list}}.
#' @param verbose A logical value indicating whether to print additional messages to the console. Default is FALSE.
#'
#' @return A tibble containing the loaded data.
#'
#' @examples
#' \dontrun{
#' data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE)
#' }
#'
#' @import tidyverse
#'
#' @export

file_name <- "municipal_harm"

load_gerda_web <- function(file_name, verbose = FALSE) {
    # Load data dict
    data(data_dictionary, envir = environment(), package = "gerda")

    if (!exists("data_dictionary")) {
        stop("Data dictionary not found. Please ensure the package is installed correctly.")
    }

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
            stop(
                "File name not found in data dictionary.\nDid you mean: \"",
                close_matches[1], "\"?"
            )
        } else {
            stop("File name not found in data dictionary")
        }
    }

    if (verbose) {
        message("File name found in data dictionary")
    }

    # Get the url

    url <- data_dictionary %>%
        filter(data_name == file_name) %>%
        pull(csv_url)

    if (verbose) {
        message("URL found: ", url)
        message("Loading data...")
    }

    # Load the data
    data <- tryCatch(
        {
            read_csv(url)
        },
        error = function(e) {
            stop("Error loading data: ", e$message)
        }
    )

    if (verbose && !inherits(data, "try-error")) {
        message("Data loaded successfully")
    }

    return(data)
}
