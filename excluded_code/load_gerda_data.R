#' Load GERDA Data
#'
#' This function loads GERDA data .
#'
#' @param file_name A character string specifying the name of the file to load. For a list of available data, see \code{\link{gerda_data_list}}.
#' @param file_format A character string specifying the format of the file. Must be either "csv" or "rds".
#'
#' @return A tibble containing the loaded data.
#'
#' @examples
#' \dontrun{
#' data <- load_gerda_data("municipal_harm", "csv")
#' }
#'
#' @export
#'
load_gerda_data <- function(file_name, file_format = c("csv", "rds")) {
    # Check if format is csv or rds -- if not, stop

    if (file_format != "csv" && file_format != "rds") {
        stop("File format must be 'csv' or 'rds'")
    }

    # Load data dict

    data_dict <- read_rds("data/data_dictionary.rds")

    # Check if file_name is in data_dict

    if (!file_name %in% data_dict$data_name) {
        # Check if there is a close match in data_di    ct$data_name

        close_matches <- agrep(file_name, data_dict$data_name, max.distance = 0.5, value = TRUE)

        if (length(close_matches) > 0) {
            distances <- stringdist::stringdist(file_name, close_matches, method = "lv")
            close_matches <- close_matches[order(distances)]
        }

        if (length(close_matches) > 0) {
            stop("File name not found in data dictionary. Did you mean: \"", close_matches[1], "\"?")
        } else {
            stop("File name not found in data dictionary")
        }
    }

    # Get the file path
    # File path is data/[format]/[file_name].[format]

    file_path <- file.path("data", file_format, paste0(file_name, ".", file_format))

    # Check if file exists
    if (!file.exists(file_path)) {
        stop("File not found -- this should not happen. Please report this bug to the package maintainer.")
    }

    # Load the data
    if (file_format == "csv") {
        data <- read_csv(file_path)
    } else if (file_format == "rds") {
        data <- read_rds(file_path)
    } else {
        stop("Unsupported file format")
    }

    return(data)
}
