# Example: How to use county_covariates with GERDA election data
# This demonstrates the recommended workflow

library(gerda)
library(dplyr)

cat("=== Example: Merging INKAR covariates with GERDA election data ===\n\n")

# 1. Load GERDA election data
cat("1. Loading GERDA federal election data (harmonized, county level)...\n")
elections <- load_gerda_web("federal_cty_harm", verbose = FALSE)

cat("   Elections: ", nrow(elections), "rows,", 
    length(unique(elections$county_code)), "counties,",
    length(unique(elections$election_year)), "elections\n")
cat("   Years:", paste(sort(unique(elections$election_year)), collapse = ", "), "\n\n")

# 2. Load covariates (built-in data)
cat("2. Loading county covariates (built-in data)...\n")
data(county_covariates)

cat("   Covariates:", nrow(county_covariates), "rows,",
    length(unique(county_covariates$county_code)), "counties,",
    min(county_covariates$year), "-", max(county_covariates$year), "\n\n")

# 3. Merge with GERDA on the LEFT (keeps only election years)
cat("3. Merging: GERDA left, covariates right...\n")
merged <- elections %>%
  left_join(
    county_covariates,
    by = c("county_code" = "county_code", "election_year" = "year")
  )

cat("   Result:", nrow(merged), "rows (same as elections!)\n")
cat("   Years in merged data:", paste(sort(unique(merged$election_year)), collapse = ", "), "\n")
cat("   Match rate (has covariate data):", 
    round(100 * sum(!is.na(merged$median_age)) / nrow(merged), 1), "%\n\n")

# 4. Check data quality
cat("4. Data availability by variable:\n")
covar_cols <- c("share_65plus", "unemployment_rate", "gdp_per_capita", 
                "median_income", "share_abitur")

for (col in covar_cols) {
  available <- sum(!is.na(merged[[col]]))
  pct <- round(100 * available / nrow(merged), 1)
  cat(sprintf("   %-25s: %4d/%4d (%5.1f%%)\n", col, available, nrow(merged), pct))
}

# 5. Example analysis: unemployment and AfD vote share
cat("\n5. Example: Correlation between unemployment and AfD vote (2017, 2021)...\n")

analysis <- merged %>%
  filter(election_year >= 2017) %>%
  select(county_code, election_year, afd, unemployment_rate) %>%
  filter(!is.na(unemployment_rate), !is.na(afd))

cat("   Observations:", nrow(analysis), "\n")

if (nrow(analysis) > 0) {
  cor_result <- cor(analysis$unemployment_rate, analysis$afd, use = "complete.obs")
  cat("   Correlation:", round(cor_result, 3), "\n\n")
  
  # Show some examples
  cat("   Sample data:\n")
  analysis %>%
    arrange(desc(afd)) %>%
    head(5) %>%
    mutate(afd = round(afd, 1), unemployment_rate = round(unemployment_rate, 1)) %>%
    print()
}

cat("\n=== Summary ===\n")
cat("✓ County covariates successfully merged with GERDA election data\n")
cat("✓ Only election years retained (due to left join)\n")
cat("✓ Ready for analysis!\n")

