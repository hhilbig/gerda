#' List of GERDA Data
#'
#' This function lists the available GERDA data sets. Each data set is available in csv and rds format.
#'
#' @return A tibble listing the available GERDA data with descriptions.
#'
#' @examples
#' \dontrun{
#' gerda_data_list()
#' }

#' @export
gerda_data_list <- function() {
    data_dict <- read_rds("data/data_dictionary.rds")
    return(data_dict)
}
