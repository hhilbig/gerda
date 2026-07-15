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
#' The returned tibble carries structured metadata beyond the name and
#' description. Use `print_table = FALSE` to access these columns:
#' \describe{
#'   \item{election_type}{`municipal`, `state`, `federal`, `county-kreistag`,
#'     `european`, `mayoral`, `landrat`, `crosswalk`, or `covariate`.}
#'   \item{geographic_level}{`municipality`, `county`, `wahlkreis`, or `person`.}
#'   \item{year_start, year_end}{Election year range, or `NA` where the
#'     dataset has no explicit stated span (e.g. crosswalks and covariates).}
#'   \item{boundary}{Harmonization target (`unharmonized`, `harmonized`,
#'     `current`, `raw`, `2021`, `2023`, `2025`, or `NA`).}
#'   \item{formats}{Available download formats (`"csv,rds"` or `"rds"`).}
#'   \item{candidate_info}{`TRUE` if the dataset includes person-level
#'     candidate / office-holder identities.}
#' }
#'
#' @return A tibble containing the available GERDA data with descriptions and
#'         structured metadata. When print_table = TRUE, the function prints a
#'         formatted table (name and description) to the console and invisibly
#'         returns the full tibble. When print_table = FALSE, the function
#'         directly returns the tibble.
#' @param print_table A logical value indicating whether to print the table in the console (TRUE) or return the data as a tibble (FALSE). Default is TRUE.
#'
#' @examples
#' gerda_data_list()
#'
#' # Access the structured metadata (geographic level, years, formats, ...)
#' meta <- gerda_data_list(print_table = FALSE)
#' meta[meta$election_type == "federal", ]
#'
#' @export
#'
gerda_data_list <- function(print_table = TRUE) {
    if (!isTRUE(print_table) && !isFALSE(print_table)) {
        stop("print_table must be TRUE or FALSE")
    }

    # Source from the single catalog so the list can never drift from what
    # load_gerda_web() can actually download. Drop the internal `path` column;
    # keep data_name and description first for backwards compatibility.
    catalog <- gerda_catalog()
    data <- tibble::as_tibble(catalog[, c(
        "data_name", "description", "election_type", "geographic_level",
        "year_start", "year_end", "boundary", "formats", "candidate_info"
    )])

    if (!print_table) {
        return(data)
    } else {
        # Print one dataset per line as "name  description" so long descriptions
        # are never truncated (the previous kable-based output wrapped or
        # elided, making pairs like federal_muni_harm_21 / _25 indistinguishable
        # by description in narrow terminals). The structured columns are
        # available via print_table = FALSE.
        name_width <- max(nchar(data$data_name)) + 2L
        for (i in seq_len(nrow(data))) {
            cat(format(data$data_name[i], width = name_width),
                data$description[i], "\n", sep = "")
        }
        invisible(data)
    }
}
