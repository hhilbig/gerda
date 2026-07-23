# Catalog coverage: every exposed dataset name must pass validation and route
# to a load attempt without producing validation warnings. We do not assert
# that the download actually succeeds (network-dependent).

catalog_datasets <- list(
    municipal = c(
        "municipal_unharm",
        "municipal_harm",
        "municipal_harm_25"
    ),
    state = c(
        "state_unharm",
        "state_harm",
        "state_harm_21",
        "state_harm_23",
        "state_harm_25"
    ),
    state_wkr = c(
        "ltw_wkr_unharm",
        "ltw_wkr_unharm_long"
    ),
    federal_muni = c(
        "federal_muni_raw",
        "federal_muni_unharm",
        "federal_muni_harm_21",
        "federal_muni_harm_25"
    ),
    federal_cty = c(
        "federal_cty_unharm",
        "federal_cty_harm"
    ),
    federal_wkr = c(
        "federal_wkr_unharm",
        "federal_wkr_unharm_long",
        "federal_wkr_2021_on_2025"
    ),
    county = c(
        "county_elec_unharm",
        "county_elec_harm_21_cty",
        "county_elec_harm_21_muni",
        "county_council_seats"
    ),
    european = c(
        "european_muni_unharm",
        "european_muni_harm"
    ),
    mayoral = c(
        "mayoral_unharm",
        "mayoral_harm",
        "mayoral_candidates",
        "mayor_panel",
        "mayor_panel_harm",
        "mayor_panel_annual",
        "mayor_panel_annual_harm"
    ),
    landrat = c(
        "landrat_unharm",
        "landrat_candidates"
    ),
    crosswalks = c(
        "ags_crosswalks",
        "cty_crosswalks",
        "wkr_2021_to_2025_crosswalk",
        "ags_1990_to_2023_crosswalk",
        "ags_1990_to_2025_crosswalk",
        "crosswalk_ags_2021_to_2023",
        "crosswalk_ags_2021_2022_to_2023",
        "crosswalk_ags_2023_to_2025",
        "crosswalk_ags_2023_24_to_2025",
        "crosswalk_ags_2024_to_2025"
    ),
    covariates = c(
        "ags_area_pop_emp",
        "ags_area_pop_emp_2023",
        "cty_area_pop_emp"
    )
)

rds_only <- c(
    "crosswalk_ags_2023_to_2025",
    "crosswalk_ags_2023_24_to_2025",
    "crosswalk_ags_2024_to_2025"
)

for (family in names(catalog_datasets)) {
    local({
        fam  <- family
        dsets <- catalog_datasets[[fam]]
        test_that(paste0("load_gerda_web accepts ", fam, " datasets (n=", length(dsets), ")"), {
            # These tests actually download each dataset from GitHub.
            # Skip on CRAN to avoid flaky network checks and long runtimes.
            skip_on_cran()
            for (ds in dsets) {
                # Assert the download actually returns data, not just that the
                # call is silent: an entry whose file 404s upstream returns NULL
                # (warning suppressed), so a lenient expect_silent() would miss
                # broken/orphaned catalog entries. Retries absorb transient
                # network flakiness; a genuine 404 still fails here.
                res <- suppressWarnings(suppressMessages(
                    load_gerda_web(ds, verbose = FALSE)
                ))
                expect_s3_class(res, "data.frame")
                expect_gt(nrow(res), 0)
            }
        })
    })
}

test_that("all cataloged names appear in gerda_data_list()", {
    listed <- gerda_data_list(print_table = FALSE)$data_name
    cataloged <- unlist(catalog_datasets, use.names = FALSE)
    expect_setequal(cataloged, listed)
})

test_that("catalog total matches the data_list row count", {
    total <- length(unlist(catalog_datasets, use.names = FALSE))
    listed_n <- nrow(gerda_data_list(print_table = FALSE))
    expect_equal(total, listed_n)
})

test_that("RDS-only datasets can be requested with file_format='rds'", {
    skip_on_cran()
    for (ds in rds_only) {
        expect_silent({
            suppressWarnings(suppressMessages(
                load_gerda_web(ds, file_format = "rds", verbose = FALSE)
            ))
        })
    }
})

test_that("requesting csv for an RDS-only dataset fails informatively", {
    # Fails on the format guard before any download, so this runs offline.
    for (ds in rds_only) {
        expect_warning(
            res <- load_gerda_web(ds, file_format = "csv"),
            "not available in 'csv' format"
        )
        expect_null(res)
        expect_error(
            load_gerda_web(ds, file_format = "csv", on_error = "stop"),
            "not available in 'csv' format"
        )
    }
})

test_that("xz-compressed RDS loads (regression: ags_1990_to_2025_crosswalk)", {
    # Some upstream RDS files are xz-compressed, which readr::read_rds cannot
    # stream from a URL. load_gerda_web must download to a tempfile so base
    # readRDS() can auto-detect the compression.
    skip_on_cran()
    data <- tryCatch(
        suppressWarnings(suppressMessages(
            load_gerda_web("ags_1990_to_2025_crosswalk", file_format = "rds", verbose = FALSE)
        )),
        error = function(e) NULL
    )
    skip_if(is.null(data), "ags_1990_to_2025_crosswalk could not be downloaded (network)")
    expect_s3_class(data, "data.frame")
    expect_gt(nrow(data), 1e5)  # upstream file is ~451,772 rows
})
