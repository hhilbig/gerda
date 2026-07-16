# Internal validation and reporting helpers shared by the GERDA join functions.

validate_gerda_unmatched <- function(unmatched) {
  choices <- c("warn", "error", "ignore")
  if (!is.character(unmatched) || length(unmatched) != 1L ||
      is.na(unmatched) || !unmatched %in% choices) {
    stop(
      "unmatched must be one of \"warn\", \"error\", or \"ignore\"",
      call. = FALSE
    )
  }
  unmatched
}

validate_gerda_identifier <- function(x, name, width) {
  if (!is.character(x)) {
    stop(
      "'", name, "' must be a character vector containing exactly ", width,
      " digits. Numeric identifiers can lose leading zeros; convert them from ",
      "the original source before joining.",
      call. = FALSE
    )
  }

  present <- !is.na(x)
  malformed <- present &
    (nchar(x, type = "chars") != width | !grepl("^[0-9]+$", x))
  if (any(malformed)) {
    examples <- utils::head(unique(x[malformed]), 3L)
    stop(
      "'", name, "' must contain exactly ", width,
      " digits when non-missing. Invalid value(s): ",
      paste0("'", examples, "'", collapse = ", "), ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_gerda_year <- function(x, name = "election_year") {
  if (!is.numeric(x) || inherits(x, c("Date", "POSIXct", "POSIXlt"))) {
    stop("'", name, "' must be a numeric or integer year column", call. = FALSE)
  }

  malformed <- !is.na(x) & (!is.finite(x) | x != floor(x))
  if (any(malformed)) {
    examples <- utils::head(unique(x[malformed]), 3L)
    stop(
      "'", name, "' must contain whole calendar years when non-missing. ",
      "Invalid value(s): ", paste(examples, collapse = ", "), ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_gerda_join_key <- function(data, keys, label) {
  missing_columns <- setdiff(keys, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      label, " is missing join-key column(s): ",
      paste(missing_columns, collapse = ", "), ".",
      call. = FALSE
    )
  }

  key_data <- data[keys]
  incomplete <- !stats::complete.cases(key_data)
  if (any(incomplete)) {
    stop(
      label, " contains ", sum(incomplete),
      " row(s) with missing join keys: ", paste(keys, collapse = ", "), ".",
      call. = FALSE
    )
  }

  duplicated_key <- duplicated(key_data) | duplicated(key_data, fromLast = TRUE)
  if (any(duplicated_key)) {
    stop(
      label, " must be unique on ", paste(keys, collapse = " + "),
      "; found ", sum(duplicated_key), " row(s) sharing duplicate keys.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

assert_no_gerda_join_conflicts <- function(election_data, reference_data,
                                           reference_keys, helper) {
  payload <- setdiff(names(reference_data), reference_keys)
  conflicts <- intersect(names(election_data), payload)
  if (length(conflicts) > 0L) {
    stop(
      helper, "() cannot add columns already present in election_data: ",
      paste(conflicts, collapse = ", "),
      ". Remove or rename the existing columns before joining.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

gerda_key_string <- function(data, keys) {
  complete <- stats::complete.cases(data[keys])
  out <- rep(NA_character_, nrow(data))
  if (!any(complete)) {
    return(out)
  }

  pieces <- lapply(data[complete, keys, drop = FALSE], function(x) {
    x <- as.character(x)
    paste0(nchar(x, type = "chars"), ":", x)
  })
  out[complete] <- do.call(paste, c(pieces, sep = "|"))
  out
}

gerda_match_keys <- function(input_data, reference_data,
                             input_keys, reference_keys) {
  input_key <- gerda_key_string(input_data, input_keys)
  reference_key <- gerda_key_string(reference_data, reference_keys)
  !is.na(input_key) & input_key %in% reference_key
}

gerda_count_units <- function(identifier, rows) {
  length(unique(identifier[rows & !is.na(identifier)]))
}

gerda_temp_name <- function(existing, base = "..gerda_join_id") {
  candidate <- base
  suffix <- 0L
  while (candidate %in% existing) {
    suffix <- suffix + 1L
    candidate <- paste0(base, suffix)
  }
  candidate
}

make_gerda_join_report <- function(helper, data_level, identifier_name,
                                   identifier, join_keys, matched,
                                   outside_coverage, missing_keys,
                                   output_rows, unmatched_action,
                                   coverage_start = NA_integer_,
                                   coverage_end = NA_integer_,
                                   outside_years = integer(0)) {
  unmatched_rows <- !matched
  unexpected_unmatched <- unmatched_rows & !outside_coverage
  eligible <- !outside_coverage
  eligible_n <- sum(eligible)
  matched_eligible_n <- sum(matched & eligible)

  unexpected_ids <- sort(unique(
    identifier[unexpected_unmatched & !is.na(identifier)]
  ))
  outside_years <- sort(unique(as.integer(outside_years[!is.na(outside_years)])))
  matched_units_n <- gerda_count_units(identifier, matched)
  unmatched_units_n <- gerda_count_units(identifier, unmatched_rows)
  outside_units_n <- gerda_count_units(identifier, outside_coverage)
  unexpected_units_n <- gerda_count_units(identifier, unexpected_unmatched)

  tibble::tibble(
    helper = helper,
    data_level = data_level,
    identifier = identifier_name,
    join_keys = list(as.character(join_keys)),
    input_rows = as.integer(length(matched)),
    output_rows = as.integer(output_rows),
    eligible_rows = as.integer(eligible_n),
    matched_rows = as.integer(sum(matched)),
    unmatched_rows = as.integer(sum(unmatched_rows)),
    outside_coverage_rows = as.integer(sum(outside_coverage)),
    unexpected_unmatched_rows = as.integer(sum(unexpected_unmatched)),
    missing_key_rows = as.integer(sum(missing_keys)),
    matched_units = as.integer(matched_units_n),
    unmatched_units = as.integer(unmatched_units_n),
    outside_coverage_units = as.integer(outside_units_n),
    unexpected_unmatched_units = as.integer(unexpected_units_n),
    eligible_match_rate = if (eligible_n == 0L) {
      NA_real_
    } else {
      matched_eligible_n / eligible_n
    },
    coverage_start = as.integer(coverage_start),
    coverage_end = as.integer(coverage_end),
    unmatched_action = unmatched_action,
    unexpected_unmatched_identifiers = list(unexpected_ids),
    outside_coverage_years = list(outside_years)
  )
}

assert_gerda_row_count <- function(input_rows, output_rows, helper) {
  if (input_rows != output_rows) {
    stop(
      helper, "() changed the row count from ", input_rows, " to ",
      output_rows, ". The reference join key is not many-to-one.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

signal_gerda_join_report <- function(report) {
  outside_n <- report$outside_coverage_rows[[1]]
  if (outside_n > 0L) {
    message(
      report$helper[[1]], "(): ", outside_n, " row(s) across ",
      report$outside_coverage_units[[1]], " unit(s) fall outside the ",
      report$coverage_start[[1]], "-", report$coverage_end[[1]],
      " reference-data coverage and were retained with missing joined values."
    )
  }

  unexpected_n <- report$unexpected_unmatched_rows[[1]]
  action <- report$unmatched_action[[1]]
  if (unexpected_n == 0L || action == "ignore") {
    return(invisible(NULL))
  }

  identifiers <- report$unexpected_unmatched_identifiers[[1]]
  example_text <- if (length(identifiers) == 0L) {
    ""
  } else {
    paste0(
      " Example identifier(s): ",
      paste(utils::head(identifiers, 5L), collapse = ", "), "."
    )
  }
  missing_text <- if (report$missing_key_rows[[1]] == 0L) {
    ""
  } else {
    paste0(" Missing join keys occur in ", report$missing_key_rows[[1]], " row(s).")
  }
  msg <- paste0(
    report$helper[[1]], "(): ", unexpected_n, " of ",
    report$eligible_rows[[1]], " eligible row(s) across ",
    report$unexpected_unmatched_units[[1]],
    " unit(s) did not match the reference data. All input rows were retained.",
    missing_text, example_text
  )

  if (action == "error") {
    stop(msg, call. = FALSE)
  }
  warning(msg, call. = FALSE)
  invisible(NULL)
}

attach_gerda_join_report <- function(result, input, report) {
  previous <- attr(input, "gerda_join_diagnostics", exact = TRUE)
  if (is.null(previous)) {
    diagnostics <- report
  } else {
    diagnostics <- dplyr::bind_rows(previous, report)
  }
  attr(result, "gerda_join_diagnostics") <- diagnostics
  result
}

#' Inspect GERDA Join Diagnostics
#'
#' Returns the machine-readable reports attached by [add_gerda_covariates()]
#' and [add_gerda_census()]. Both helpers preserve earlier reports, so a pipe
#' that performs both joins returns one row per join in execution order.
#'
#' @param x A data frame returned by `add_gerda_covariates()` or
#'   `add_gerda_census()`.
#'
#' @return A tibble with one row per GERDA join and the following columns:
#'   \describe{
#'     \item{helper, data_level, identifier, join_keys}{The helper, inferred
#'       geographic level, identifier column, and join-key mapping. `join_keys`
#'       is a list-column.}
#'     \item{input_rows, output_rows}{Row counts before and after the join.}
#'     \item{eligible_rows, matched_rows, unmatched_rows}{Rows eligible for
#'       matching after excluding temporal out-of-coverage rows, plus total
#'       matched and unmatched rows. Census joins treat every row as eligible.}
#'     \item{outside_coverage_rows, unexpected_unmatched_rows,
#'       missing_key_rows}{Unmatched-row classifications. A missing join key is
#'       unexpected, even when another key would fall outside coverage.}
#'     \item{matched_units, unmatched_units, outside_coverage_units,
#'       unexpected_unmatched_units}{Counts of distinct non-missing geographic
#'       identifiers in each category.}
#'     \item{eligible_match_rate}{Matched eligible rows divided by all eligible
#'       rows, or `NA` if there are no eligible rows.}
#'     \item{coverage_start, coverage_end}{Temporal reference-data coverage;
#'       `NA` for the time-invariant Census join.}
#'     \item{unmatched_action}{The requested `unmatched` mode.}
#'     \item{unexpected_unmatched_identifiers,
#'       outside_coverage_years}{List-columns containing the distinct values in
#'       each category. Missing identifiers are counted in `missing_key_rows`
#'       but cannot appear in the identifier list.}
#'   }
#'
#' @details
#' The diagnostics are stored as an attribute and are intended to be inspected
#' immediately after the join pipeline. The GERDA join helpers preserve the
#' full history, but unrelated data-frame transformations may remove custom
#' attributes.
#'
#' @examples
#' census <- gerda_census()
#' election_data <- data.frame(ags = head(census$ags, 2))
#' joined <- add_gerda_census(election_data, unmatched = "error")
#' gerda_join_diagnostics(joined)
#'
#' @seealso [add_gerda_covariates()], [add_gerda_census()]
#' @export
gerda_join_diagnostics <- function(x) {
  if (!is.data.frame(x)) {
    stop("x must be a data frame returned by a GERDA join helper", call. = FALSE)
  }
  diagnostics <- attr(x, "gerda_join_diagnostics", exact = TRUE)
  if (is.null(diagnostics)) {
    stop(
      "x does not contain GERDA join diagnostics; call this function ",
      "immediately after add_gerda_covariates() or add_gerda_census().",
      call. = FALSE
    )
  }
  diagnostics
}
