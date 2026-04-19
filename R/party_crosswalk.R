#' Map GERDA Party Names to ParlGov Attributes
#'
#' @description
#' Creates a crosswalk between GERDA party names and ParlGov's `view_party` attributes.
#' If a party name is not found, the corresponding output element is `NA`. This function
#' expects GERDA party names (lowercase, underscores); other naming schemes will mostly
#' return `NA`.
#'
#' @param party_gerda A character vector containing the GERDA party names to be converted.
#' @param destination A single string naming the target column. Available destinations:
#'   \itemize{
#'     \item \strong{Names}: `party_name`, `party_name_ascii`, `party_name_short`, `party_name_english`
#'     \item \strong{Party family}: `family_name`, `family_name_short`
#'     \item \strong{Ideology scales (ParlGov)}: `left_right`, `state_market`, `liberty_authority`, `eu_anti_pro`
#'     \item \strong{External ideology scores}: `cmp`, `euprofiler`, `ees`, `castles_mair`, `huber_inglehart`, `ray`, `benoit_laver`, `chess`
#'     \item \strong{Identifiers}: `country_id`, `party_id`, `family_id`
#'   }
#' @return A vector of the same length as `party_gerda` with the mapped values.
#' @export
#' @examples
#' party_crosswalk(c("cdu", "spd", "linke_pds", NA), "left_right")
#' party_crosswalk(c("cdu", "afd"), "family_name_short")
#'
party_crosswalk <- function(party_gerda, destination) {
    lt <- lookup_table
    available <- setdiff(colnames(lt), "party_gerda")

    # Length of destination must be 1
    if (length(destination) != 1) {
        stop("destination must be a single character string. Available destinations: ",
             paste(available, collapse = ", "))
    }

    # Check if destination is a column name of lt
    if (!destination %in% colnames(lt)) {
        stop("'", destination, "' is not a valid destination. Available destinations: ",
             paste(available, collapse = ", "))
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
