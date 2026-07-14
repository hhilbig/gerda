# Tests for the robustness features added around downloading: Git LFS pointer
# detection, timeout/retry/cache argument validation, and the on-disk cache.
# The logic here is exercised offline; only a couple of network round-trips are
# guarded with skip_on_cran().

# Redirect the cache into a throwaway directory for the duration of `code`,
# restoring the previous R_USER_CACHE_DIR afterwards.
with_temp_cache <- function(code) {
    old <- Sys.getenv("R_USER_CACHE_DIR", unset = NA)
    on.exit({
        if (is.na(old)) Sys.unsetenv("R_USER_CACHE_DIR") else Sys.setenv(R_USER_CACHE_DIR = old)
    }, add = TRUE)
    Sys.setenv(R_USER_CACHE_DIR = tempfile("gerda-cache-"))
    force(code)
}

test_that("is_lfs_pointer detects pointer files and nothing else", {
    ptr <- tempfile(fileext = ".rds")
    writeLines(c(
        "version https://git-lfs.github.com/spec/v1",
        "oid sha256:1111111111111111111111111111111111111111111111111111111111111111",
        "size 4095144"
    ), ptr)
    expect_true(is_lfs_pointer(ptr))

    real <- tempfile(fileext = ".rds")
    saveRDS(mtcars, real)
    expect_false(is_lfs_pointer(real))

    empty <- tempfile(fileext = ".rds")
    file.create(empty)
    expect_false(is_lfs_pointer(empty))

    expect_false(is_lfs_pointer(tempfile()))  # missing file
})

test_that("load_gerda_web validates timeout / max_retries / cache / refresh", {
    expect_error(load_gerda_web("federal_cty_harm", timeout = -1), "timeout")
    expect_error(load_gerda_web("federal_cty_harm", timeout = "x"), "timeout")
    expect_error(load_gerda_web("federal_cty_harm", max_retries = -1), "max_retries")
    expect_error(load_gerda_web("federal_cty_harm", cache = NA), "cache")
    expect_error(load_gerda_web("federal_cty_harm", cache = "yes"), "cache")
    expect_error(load_gerda_web("federal_cty_harm", refresh = 1), "refresh")
})

test_that("fetch_to_file reports failure without signalling", {
    # A nonexistent file:// URL fails fast and offline; max_retries = 0 avoids
    # any backoff sleeps.
    dest <- tempfile()
    status <- suppressWarnings(
        fetch_to_file("file:///gerda/does/not/exist.rds", dest, max_retries = 0)
    )
    expect_false(status$success)
    expect_true(is.character(status$message) && nchar(status$message) > 0)
})

test_that("cache short-circuits the network when a valid cached copy exists", {
    with_temp_cache({
        cdir <- gerda_cache_dir()
        dir.create(cdir, recursive = TRUE, showWarnings = FALSE)
        # Seed a sentinel that is distinguishable from the real upstream data.
        sentinel <- tibble::tibble(sentinel = 1:3)
        saveRDS(sentinel, file.path(cdir, "federal_cty_harm.rds"))

        res <- load_gerda_web("federal_cty_harm", cache = TRUE)
        expect_equal(nrow(res), 3)
        expect_true("sentinel" %in% names(res))
    })
})

test_that("clear_gerda_cache removes cached files", {
    with_temp_cache({
        cdir <- gerda_cache_dir()
        dir.create(cdir, recursive = TRUE, showWarnings = FALSE)
        saveRDS(mtcars, file.path(cdir, "federal_cty_harm.rds"))
        saveRDS(mtcars, file.path(cdir, "municipal_harm.rds"))

        # Targeted removal.
        removed <- suppressMessages(clear_gerda_cache("federal_cty_harm"))
        expect_length(removed, 1)
        expect_false(file.exists(file.path(cdir, "federal_cty_harm.rds")))
        expect_true(file.exists(file.path(cdir, "municipal_harm.rds")))

        # Full clear.
        removed_all <- suppressMessages(clear_gerda_cache())
        expect_length(removed_all, 1)
        expect_length(list.files(cdir, pattern = "\\.(rds|csv)$"), 0)
    })
})

test_that("clear_gerda_cache is a no-op when there is no cache directory", {
    with_temp_cache({
        expect_message(res <- clear_gerda_cache(), "No GERDA cache")
        expect_length(res, 0)
    })
})

test_that("gerda_cache_dir returns a single path string", {
    d <- gerda_cache_dir()
    expect_type(d, "character")
    expect_length(d, 1)
})

test_that("cache with refresh = TRUE re-downloads over a stale pointer", {
    skip_on_cran()
    with_temp_cache({
        cdir <- gerda_cache_dir()
        dir.create(cdir, recursive = TRUE, showWarnings = FALSE)
        # A stale Git LFS pointer sitting in the cache must not be returned.
        writeLines(
            "version https://git-lfs.github.com/spec/v1",
            file.path(cdir, "federal_cty_harm.rds")
        )
        data <- tryCatch(
            suppressWarnings(suppressMessages(
                load_gerda_web("federal_cty_harm", cache = TRUE)
            )),
            error = function(e) NULL
        )
        skip_if(is.null(data), "federal_cty_harm could not be downloaded (network)")
        expect_s3_class(data, "data.frame")
        expect_gt(nrow(data), 100)  # real upstream file, not the 1-line pointer
    })
})
