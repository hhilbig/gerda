# Prepare INKAR county covariates for inclusion as built-in package data
# This script creates the final dataset that will be shipped with the GERDA package

library(dplyr)

cat("=== Preparing INKAR covariates for GERDA package ===\n\n")

# Load the full INKAR dataset
cat("Loading INKAR data...\n")
inkar_full <- readRDS("data_not_used/rds/inkar_county_covariates.rds")

# Prepare for merging with GERDA:
# 1. Convert 8-digit county codes to 5-digit (to match GERDA)
# 2. Keep all years (user will filter when merging)
# 3. Rename to make clear it's for merging

county_covariates <- inkar_full |>
  mutate(
    county_code = substr(county_code, 1, 5)  # Convert to 5-digit
  ) |>
  select(-county_name) |>  # Remove county_name to avoid conflicts in merge
  arrange(county_code, year)

# Summary
cat("\n=== Dataset Summary ===\n")
cat("Counties:", length(unique(county_covariates$county_code)), "\n")
cat("Years:", min(county_covariates$year), "-", max(county_covariates$year), "\n")
cat("Observations:", nrow(county_covariates), "\n")
cat("Variables:", ncol(county_covariates), "\n")

cat("\nVariable names:\n")
print(names(county_covariates))

cat("\n=== Sample data ===\n")
county_covariates |>
  filter(county_code == "01001", year >= 2017) |>
  select(county_code, year, share_65plus, unemployment_rate, median_income) |>
  print()

# Save for package
cat("\n=== Saving ===\n")
cat("Saving to data_not_used/county_covariates.rda for package inclusion...\n")
save(county_covariates, file = "data_not_used/county_covariates.rda", compress = "xz")

cat("\n✓ Done!\n")
cat("\nNext steps:\n")
cat("1. Copy data_not_used/county_covariates.rda to data/ folder\n")
cat("2. Create R/county_covariates.R with documentation\n")
cat("3. Run devtools::document() to update package\n")

