#' GERDA
#'
#' @description
#' This function creates a crosswalk between parties and their corresponding names using the ParlGov view_party table. In cases where the party name is not found in the view_party table, the function returns NA. Note that this function should be run on GERDA party names, and will likely not work on other party naming schemes.
#'
#' @param party_gerda A character vector containing the GERDA party names to be converted.
#' @param destination The name of the column in the view_party table to map to.
#' @return A vector with the mapped party names.
#' @export
#' @examples
#' party_crosswalk(c("cdu", "spd", "linke_pds", NA), "left_right")
#'
party_crosswalk <- function(party_gerda, destination) {
    lt <- lookup_table

    # Length of destination must be 1
    if (length(destination) != 1) {
        stop("destination must be single character string")
    }

    # Check if destination is a column name of lt
    if (!destination %in% colnames(lt)) {
        stop("destination must be a column of the view_party table")
    }

    # Check if party_gerda is a character vector
    if (!is.character(party_gerda)) {
        stop("party_gerda must be a character vector")
    }

    # Determine the type of NA to use based on the destination column
    na_value <- if (is.numeric(lt[[destination]])) NA_real_ else NA_character_

    # Match party_gerda values with lookup table and return corresponding destination values
    lookup_result <- lt[[destination]][match(party_gerda, lt$party_gerda)]

    # Replace any NA results with the appropriate NA type
    lookup_result[is.na(lookup_result)] <- na_value

    return(lookup_result)
}
