# ============================================================================
# WORKFLOW: Adding INKAR County Covariates to GERDA Election Data
# ============================================================================
#
# This script demonstrates the complete workflow for merging INKAR covariates
# with GERDA election data at the county level.
#
# ============================================================================

library(gerda)
library(dplyr)

# ============================================================================
# STEP 1: Load GERDA Election Data
# ============================================================================

cat("=== STEP 1: Load GERDA Election Data ===\n\n")

# Load federal election results at county level (harmonized to 2021 boundaries)
elections <- load_gerda_web("federal_cty_harm")

cat("Loaded ", nrow(elections), " observations\n")
cat("Counties: ", length(unique(elections$county_code)), "\n")
cat(
    "Elections: ", length(unique(elections$election_year)),
    " (years: ", paste(sort(unique(elections$election_year)), collapse = ", "), ")\n\n"
)

# Preview the data
cat("Preview:\n")
elections %>%
    select(county_code, state, election_year, turnout, cdu, spd, afd) %>%
    head(5) %>%
    print()

# ============================================================================
# STEP 2: Explore County Covariates
# ============================================================================

cat("\n=== STEP 2: Explore County Covariates ===\n\n")

# View the codebook to understand available variables
cat("Available variables:\n")
covariates_codebook %>%
    select(variable, label, category, missing_pct) %>%
    print(n = 25)

# Check which variables have good data coverage
cat("\nVariables with <5% missing data:\n")
good_coverage <- covariates_codebook %>%
    filter(missing_pct < 5 | is.na(missing_pct)) %>%
    select(variable, label, category)

print(good_coverage)

# Preview the covariates data
cat("\nCovariates data preview:\n")
county_covariates %>%
    filter(county_code == "01001", year >= 2017) %>%
    select(
        county_code, year, share_65plus, unemployment_rate,
        gdp_per_capita, share_abitur
    ) %>%
    print()

# ============================================================================
# STEP 3: Merge Covariates with Election Data
# ============================================================================

cat("\n=== STEP 3: Merge Covariates with Election Data ===\n\n")

# MERGE: Use left_join with elections on the LEFT
# This automatically keeps only election years and election districts

merged <- elections %>%
    left_join(
        county_covariates,
        by = c("county_code" = "county_code", "election_year" = "year")
    )

cat("Merge complete!\n")
cat("Result: ", nrow(merged), " observations\n")
cat("Years: ", unique(merged$election_year), "\n\n")

# Check merge success
cat("Merge quality:\n")
for (var in c(
    "share_65plus", "unemployment_rate", "gdp_per_capita",
    "share_abitur", "median_income"
)) {
    available <- sum(!is.na(merged[[var]]))
    pct <- round(100 * available / nrow(merged), 1)
    cat(sprintf("  %-25s: %4d/%4d (%5.1f%%)\n", var, available, nrow(merged), pct))
}

# ============================================================================
# STEP 4: Exploratory Analysis Example
# ============================================================================

cat("\n=== STEP 4: Example Analysis ===\n\n")

# Example: Relationship between unemployment and AfD vote share (2021)
cat("Example: Unemployment and AfD vote share (2021)\n")

analysis_2021 <- merged %>%
    filter(election_year == 2021) %>%
    select(
        county_code, turnout, afd, unemployment_rate, share_65plus,
        gdp_per_capita, share_foreign
    ) %>%
    filter(!is.na(unemployment_rate))

cat("Observations with complete data: ", nrow(analysis_2021), "\n")

# Correlation
cor_unemp_afd <- cor(analysis_2021$unemployment_rate, analysis_2021$afd,
    use = "complete.obs"
)
cat("Correlation (unemployment ~ AfD): ", round(cor_unemp_afd, 3), "\n\n")

# Show top 5 counties by AfD vote share
cat("Top 5 counties by AfD vote share (2021):\n")
analysis_2021 %>%
    arrange(desc(afd)) %>%
    select(county_code, afd, unemployment_rate, share_65plus) %>%
    mutate(
        afd = round(afd * 100, 1),
        unemployment_rate = round(unemployment_rate, 1),
        share_65plus = round(share_65plus, 1)
    ) %>%
    head(5) %>%
    print()

# ============================================================================
# STEP 5: Working with Different Election Years
# ============================================================================

cat("\n=== STEP 5: Data Availability by Election Year ===\n\n")

# Check which covariates are available for each election year
yearly_coverage <- merged %>%
    group_by(election_year) %>%
    summarise(
        n_counties = n(),
        n_with_unemployment = sum(!is.na(unemployment_rate)),
        n_with_gdp = sum(!is.na(gdp_per_capita)),
        n_with_income = sum(!is.na(median_income)),
        .groups = "drop"
    ) %>%
    mutate(
        pct_unemployment = round(100 * n_with_unemployment / n_counties, 1),
        pct_gdp = round(100 * n_with_gdp / n_counties, 1),
        pct_income = round(100 * n_with_income / n_counties, 1)
    )

print(yearly_coverage)

# ============================================================================
# STEP 6: Save Merged Dataset
# ============================================================================

cat("\n=== STEP 6: Save Merged Dataset (optional) ===\n\n")

# Option 1: Save as RDS
# saveRDS(merged, "elections_with_covariates.rds")

# Option 2: Save as CSV
# write.csv(merged, "elections_with_covariates.csv", row.names = FALSE)

cat("Workflow complete! Your merged dataset is ready for analysis.\n")
cat("\nKey points:\n")
cat("✓ Use left_join with elections on the LEFT\n")
cat("✓ Keeps only election years automatically\n")
cat("✓ Check missing data patterns before analysis\n")
cat("✓ Some covariates have better coverage in recent years\n")
