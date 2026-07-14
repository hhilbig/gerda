# Download, integrity, and cache helpers for load_gerda_web().
# The exported helpers (gerda_cache_dir, clear_gerda_cache) let users inspect
# and purge the opt-in on-disk cache. The internal helpers (is_lfs_pointer,
# fetch_to_file) handle robust downloading and are not part of the public API.

#' Detect a Git LFS pointer file
#'
#' GERDA data lives behind Git LFS on GitHub. A raw request is redirected to the
#' LFS media host; if that redirect fails or is served incorrectly, the
#' "download" is a tiny text pointer file (starting with
#' `version https://git-lfs.github.com/spec/v1`) rather than the real data.
#' Reading such a file as RDS/CSV would fail cryptically, so we detect it up
#' front. The size guard keeps this cheap: real datasets are far larger than any
#' pointer file.
#'
#' @param path Path to a downloaded file.
#' @return `TRUE` if the file looks like a Git LFS pointer, otherwise `FALSE`.
#' @keywords internal
#' @noRd
is_lfs_pointer <- function(path) {
    if (!file.exists(path)) {
        return(FALSE)
    }
    sz <- file.info(path)$size
    if (is.na(sz) || sz == 0 || sz > 1024) {
        return(FALSE)
    }
    con <- file(path, "rb")
    on.exit(close(con))
    raw_bytes <- readBin(con, "raw", n = 200L)
    if (length(raw_bytes) == 0) {
        return(FALSE)
    }
    # Drop nul bytes so rawToChar() does not error, and compare byte-wise to
    # avoid locale/encoding surprises on binary content.
    txt <- rawToChar(raw_bytes[raw_bytes != as.raw(0L)])
    grepl("git-lfs.github.com/spec", txt, fixed = TRUE, useBytes = TRUE)
}

#' Download a URL to a file with a configurable timeout and retries
#'
#' Wraps [utils::download.file()] with (1) a temporarily raised download
#' timeout, (2) retry-with-backoff on transient failures, and (3) Git LFS
#' pointer detection (treated as a retryable failure). Returns a status list
#' rather than signalling, so the caller can route failures through its own
#' error-handling contract (`on_error`).
#'
#' @param url URL to fetch.
#' @param dest Destination path.
#' @param timeout Download timeout in seconds (raised only if higher than the
#'   current `options("timeout")`, and restored on exit).
#' @param max_retries Number of *additional* attempts after the first
#'   (so total attempts = `max_retries + 1`).
#' @param verbose Whether to print progress messages.
#' @return A list with `success` (logical) and, on failure, `message`.
#' @keywords internal
#' @noRd
fetch_to_file <- function(url, dest, timeout = 300, max_retries = 2,
                          verbose = FALSE) {
    old_timeout <- getOption("timeout")
    if (is.null(old_timeout) || old_timeout < timeout) {
        options(timeout = timeout)
        on.exit(options(timeout = old_timeout), add = TRUE)
    }

    attempts <- as.integer(max_retries) + 1L
    last_msg <- "Download failed for an unknown reason."

    for (i in seq_len(attempts)) {
        ok <- tryCatch(
            {
                utils::download.file(url, dest, mode = "wb", quiet = !verbose)
                TRUE
            },
            error = function(e) {
                last_msg <<- conditionMessage(e)
                FALSE
            }
        )

        if (ok && is_lfs_pointer(dest)) {
            ok <- FALSE
            last_msg <- paste0(
                "Downloaded file is a Git LFS pointer, not the actual data. ",
                "This usually means the Git LFS media redirect failed or the ",
                "download was incomplete. Check your connection and try again; ",
                "if it persists, try file_format = \"csv\" or contact the ",
                "package maintainer."
            )
        }

        if (ok) {
            return(list(success = TRUE, message = NULL))
        }

        if (i < attempts) {
            if (verbose) {
                message("Download attempt ", i, " of ", attempts,
                        " failed; retrying...")
            }
            Sys.sleep(2^(i - 1))
        }
    }

    list(success = FALSE, message = last_msg)
}

#' GERDA cache directory
#'
#' Returns the path to the directory used by [load_gerda_web()] to cache
#' downloaded datasets when `cache = TRUE` (or `options(gerda.cache = TRUE)`).
#' The location follows [tools::R_user_dir()] conventions and can be redirected
#' with the standard `R_USER_CACHE_DIR` environment variable. The directory is
#' not created until a cached download is actually written.
#'
#' @return A single character string: the cache directory path.
#' @seealso [clear_gerda_cache()], [load_gerda_web()]
#' @examples
#' gerda_cache_dir()
#' @export
gerda_cache_dir <- function() {
    tools::R_user_dir("gerda", which = "cache")
}

#' Clear the GERDA download cache
#'
#' Removes files written to the GERDA cache by [load_gerda_web()]
#' (`cache = TRUE`). Because the upstream data can be updated in place, use this
#' to force fresh downloads, or pass `cache = TRUE, refresh = TRUE` to
#' [load_gerda_web()] for a one-off refresh.
#'
#' @param data_name Optional dataset name. If supplied, only that dataset's
#'   cached CSV/RDS files are removed; otherwise the entire cache is cleared.
#' @return Invisibly, a character vector of the removed file paths.
#' @seealso [gerda_cache_dir()], [load_gerda_web()]
#' @examples
#' \donttest{
#' clear_gerda_cache()
#' }
#' @export
clear_gerda_cache <- function(data_name = NULL) {
    if (!is.null(data_name) &&
        (!is.character(data_name) || length(data_name) != 1)) {
        stop("data_name must be NULL or a single character string")
    }

    dir <- gerda_cache_dir()
    if (!dir.exists(dir)) {
        message("No GERDA cache to clear (", dir, " does not exist).")
        return(invisible(character(0)))
    }

    if (is.null(data_name)) {
        files <- list.files(dir, pattern = "\\.(rds|csv)$", full.names = TRUE)
    } else {
        files <- file.path(dir, paste0(data_name, c(".rds", ".csv")))
        files <- files[file.exists(files)]
    }

    if (length(files) == 0) {
        message("No cached files matched; nothing removed.")
        return(invisible(character(0)))
    }

    removed <- files[file.remove(files)]
    message("Removed ", length(removed), " cached file(s) from ", dir, ".")
    invisible(removed)
}
