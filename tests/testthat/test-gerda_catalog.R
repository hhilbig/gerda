# Tests for the internal catalog (single source of truth) and the structured
# metadata it surfaces through gerda_data_list(). These are all offline.

test_that("gerda_catalog() has the expected shape", {
    cat <- gerda_catalog()
    expect_s3_class(cat, "data.frame")
    expect_equal(nrow(cat), 46)
    expect_setequal(
        colnames(cat),
        c("data_name", "description", "path", "election_type",
          "geographic_level", "year_start", "year_end", "boundary",
          "formats", "candidate_info")
    )
    # Keys and paths are unique and non-empty.
    expect_equal(length(cat$data_name), length(unique(cat$data_name)))
    expect_equal(length(cat$path), length(unique(cat$path)))
    expect_true(all(nchar(cat$data_name) > 0))
    expect_true(all(nchar(cat$path) > 0))
})

test_that("catalog metadata values are in their allowed sets", {
    cat <- gerda_catalog()

    expect_true(all(cat$election_type %in% c(
        "municipal", "state", "federal", "county-kreistag",
        "european", "mayoral", "landrat", "crosswalk", "covariate"
    )))
    expect_true(all(cat$geographic_level %in%
        c("municipality", "county", "wahlkreis", "person")))
    expect_true(all(cat$boundary %in% c(
        "unharmonized", "harmonized", "current", "raw",
        "2021", "2023", "2025", NA_character_
    )))
    expect_true(all(cat$formats %in% c("csv,rds", "rds")))
    expect_type(cat$candidate_info, "logical")
    expect_false(any(is.na(cat$candidate_info)))
})

test_that("year ranges are internally consistent", {
    cat <- gerda_catalog()
    both <- !is.na(cat$year_start) & !is.na(cat$year_end)
    expect_true(all(cat$year_start[both] <= cat$year_end[both]))
    # Years, where present, are plausible German-election years (Landrat
    # elections reach back to 1945).
    yrs <- c(cat$year_start[!is.na(cat$year_start)], cat$year_end[!is.na(cat$year_end)])
    expect_true(all(yrs >= 1945 & yrs <= 2030))
})

test_that("RDS-only datasets are flagged as rds-only", {
    cat <- gerda_catalog()
    rds_only <- c(
        "crosswalk_ags_2023_to_2025",
        "crosswalk_ags_2023_24_to_2025",
        "crosswalk_ags_2024_to_2025"
    )
    expect_equal(cat$formats[cat$data_name %in% rds_only], rep("rds", 3))
    # Everything else offers both formats.
    expect_true(all(cat$formats[!cat$data_name %in% rds_only] == "csv,rds"))
})

test_that("candidate_info flags the person-level candidate datasets", {
    cat <- gerda_catalog()
    expect_setequal(
        cat$data_name[cat$candidate_info],
        c("mayoral_candidates", "mayor_panel", "mayor_panel_harm",
          "mayor_panel_annual", "mayor_panel_annual_harm", "landrat_candidates")
    )
})

test_that("gerda_data_list() exposes structured metadata columns", {
    dl <- gerda_data_list(print_table = FALSE)
    # data_name/description remain the first two columns (back-compat).
    expect_equal(colnames(dl)[1:2], c("data_name", "description"))
    expect_true(all(c(
        "election_type", "geographic_level", "year_start", "year_end",
        "boundary", "formats", "candidate_info"
    ) %in% colnames(dl)))
    # The internal-only `path` column is not surfaced to users.
    expect_false("path" %in% colnames(dl))
})
