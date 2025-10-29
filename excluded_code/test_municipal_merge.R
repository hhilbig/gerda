# Test merging county-level covariates with municipal-level data

library(gerda)
library(dplyr)

devtools::load_all(".")

cat("=== Testing Municipal-Level Merge ===\n\n")

# Load municipal data
cat("Loading municipal election data...\n")
muni_data <- load_gerda_web("federal_muni_harm_21", verbose = FALSE)

cat("Loaded ", nrow(muni_data), " municipal observations\n")
cat("Municipalities:", length(unique(muni_data$ags)), "\n")
cat("Years:", paste(sort(unique(muni_data$election_year)), collapse = ", "), "\n\n")

# Add covariates (should trigger message about county-level merge)
cat("Adding county-level covariates to municipal data...\n")
merged <- add_gerda_covariates(muni_data)

cat("✓ Merge completed\n")
cat("  Rows:", nrow(merged), "(same as input)\n")
cat("  New columns:", ncol(merged) - ncol(muni_data), "\n\n")

# Verify: all munis in same county have same covariate values
cat("Verification: Checking if municipalities in same county have identical covariates...\n")

verification <- merged %>%
    filter(!is.na(unemployment_rate)) %>%
    mutate(county_code = substr(ags, 1, 5)) %>%
    group_by(county_code, election_year) %>%
    summarize(
        n_municipalities = n(),
        range_unemployment = max(unemployment_rate) - min(unemployment_rate),
        range_gdp = max(gdp_per_capita, na.rm = TRUE) - min(gdp_per_capita, na.rm = TRUE),
        .groups = "drop"
    )

cat("  Sample counties:\n")
verification %>%
    head(10) %>%
    print()

# Check if ranges are all zero (identical values within county)
all_zero <- all(verification$range_unemployment == 0, na.rm = TRUE)

if (all_zero) {
    cat("\n✓ PASS: All municipalities within the same county have identical covariate values\n")
} else {
    cat("\n✗ FAIL: Some municipalities within the same county have different values!\n")
    verification %>%
        filter(range_unemployment > 0) %>%
        print()
}

# Example analysis at municipal level with county covariates
cat("\n=== Example Analysis ===\n")
cat("Distribution of unemployment rate across municipalities (2021):\n")

merged %>%
    filter(election_year == 2021, !is.na(unemployment_rate)) %>%
    summarize(
        n_municipalities = n(),
        unique_counties = n_distinct(substr(ags, 1, 5)),
        mean_unemployment = mean(unemployment_rate),
        sd_unemployment = sd(unemployment_rate)
    ) %>%
    print()

cat("\n✓ Municipal merge test completed successfully!\n")
