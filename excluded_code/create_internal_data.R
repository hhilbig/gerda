# Create internal data for county covariates
# This script prepares the covariates and codebook as internal package data

library(dplyr)

cat("=== Creating internal package data ===\n\n")

# Load the prepared data
cat("Loading county covariates...\n")
county_covariates_internal <- readRDS("data_not_used/rds/inkar_county_covariates.rds") %>%
    mutate(county_code = substr(county_code, 1, 5)) %>% # Ensure 5-digit codes
    select(-county_name) %>% # Remove county_name to avoid conflicts
    arrange(county_code, year)

cat("  Rows:", nrow(county_covariates_internal), "\n")
cat("  Columns:", ncol(county_covariates_internal), "\n")

# Load the codebook
cat("\nLoading codebook...\n")
load("data_not_used/covariates_codebook.rda")
covariates_codebook_internal <- covariates_codebook

cat("  Rows:", nrow(covariates_codebook_internal), "\n")

# Save as internal data (sysdata.rda)
cat("\nSaving as internal data (R/sysdata.rda)...\n")

# Check if sysdata.rda already exists
if (file.exists("R/sysdata.rda")) {
    cat("  Loading existing sysdata.rda...\n")
    load("R/sysdata.rda")

    # Add our new data to existing data
    save(
        lookup_table, # Keep existing lookup_table from party_crosswalk
        county_covariates_internal,
        covariates_codebook_internal,
        file = "R/sysdata.rda",
        compress = "xz"
    )
} else {
    # Just save our data
    save(
        county_covariates_internal,
        covariates_codebook_internal,
        file = "R/sysdata.rda",
        compress = "xz"
    )
}

cat("✓ Internal data saved to R/sysdata.rda\n")
cat("\nNext steps:\n")
cat("1. Remove data/county_covariates.rda\n")
cat("2. Remove data/covariates_codebook.rda\n")
cat("3. Remove old R/county_covariates.R and R/covariates_codebook.R\n")
cat("4. Remove LazyData: true from DESCRIPTION\n")
cat("5. Run devtools::document()\n")
