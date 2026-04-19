test_that("load_gerda_web fuzzy matching suggests close names", {
    expect_warning(
        result <- load_gerda_web("municipal_harn"), # missing 'm' from 'harm'
        "Did you mean"
    )
    expect_null(result)
    expect_warning(load_gerda_web("municipal_harn"), "gerda_data_list")

    expect_warning(
        result <- load_gerda_web("federal_muni"), # partial match
        "Did you mean"
    )
    expect_null(result)
    expect_warning(load_gerda_web("federal_muni"), "gerda_data_list")

    expect_warning(
        result <- load_gerda_web("state_unhar"), # close to 'state_unharm'
        "Did you mean"
    )
    expect_null(result)
    expect_warning(load_gerda_web("state_unhar"), "gerda_data_list")
})

test_that("deprecated federal_muni_harm returns specific guidance", {
    expect_warning(
        result <- load_gerda_web("federal_muni_harm"),
        "has been replaced with two boundary-specific versions"
    )
    expect_null(result)
    expect_warning(load_gerda_web("federal_muni_harm"), "federal_muni_harm_21")
    expect_warning(load_gerda_web("federal_muni_harm"), "federal_muni_harm_25")
    expect_warning(load_gerda_web("federal_muni_harm"), "Please replace")
    expect_warning(load_gerda_web("federal_muni_harm"), "gerda_data_list")
})
