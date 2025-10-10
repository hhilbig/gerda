# Check overlap between INKAR covariates and GERDA election data

library(dplyr)
library(gerda)

cat("=== LOADING DATA ===\n")

# Load INKAR covariates
cat("Loading INKAR covariates...\n")
inkar <- readRDS("data_not_used/rds/inkar_county_covariates.rds")

# Load GERDA county-level election data
cat("Loading GERDA federal election data (county level)...\n")
federal_cty_harm <- load_gerda_web("federal_cty_harm", verbose = FALSE)
federal_cty_unharm <- load_gerda_web("federal_cty_unharm", verbose = FALSE)

cat("\n=== DATA SUMMARIES ===\n")
cat("INKAR:\n")
cat("  Counties:", length(unique(inkar$county_code)), "\n")
cat("  Years:", min(inkar$year), "-", max(inkar$year), "\n")
cat("  Observations:", nrow(inkar), "\n")

cat("\nGERDA Federal (harmonized):\n")
cat("  Counties:", length(unique(federal_cty_harm$county_code)), "\n")
cat("  Years:", paste(sort(unique(federal_cty_harm$election_year)), collapse = ", "), "\n")
cat("  Observations:", nrow(federal_cty_harm), "\n")

cat("\nGERDA Federal (unharmonized):\n")
cat("  Counties:", length(unique(federal_cty_unharm$county_code)), "\n")
cat("  Years:", paste(sort(unique(federal_cty_unharm$election_year)), collapse = ", "), "\n")
cat("  Observations:", nrow(federal_cty_unharm), "\n")

cat("\n=== YEAR OVERLAP ===\n")
inkar_years <- sort(unique(inkar$year))
gerda_harm_years <- sort(unique(federal_cty_harm$election_year))
gerda_unharm_years <- sort(unique(federal_cty_unharm$election_year))

cat("INKAR years:", paste(range(inkar_years), collapse = "-"), "\n")
cat("GERDA harmonized years:", paste(gerda_harm_years, collapse = ", "), "\n")
cat("GERDA unharmonized years:", paste(gerda_unharm_years, collapse = ", "), "\n")

overlap_harm <- intersect(inkar_years, gerda_harm_years)
overlap_unharm <- intersect(inkar_years, gerda_unharm_years)

cat("\nOverlapping years (harmonized):", paste(overlap_harm, collapse = ", "), "\n")
cat("Overlapping years (unharmonized):", paste(overlap_unharm, collapse = ", "), "\n")

cat("\n=== COUNTY CODE OVERLAP ===\n")

# Check county code format
cat("\nINKAR county code format (first 5):\n")
print(head(unique(inkar$county_code), 5))

cat("\nGERDA harmonized county code format (first 5):\n")
print(head(unique(federal_cty_harm$county_code), 5))

cat("\nGERDA unharmonized county code format (first 5):\n")
print(head(unique(federal_cty_unharm$county_code), 5))

# Convert INKAR codes to match GERDA format (remove last 3 digits if 8 digits)
inkar_codes <- unique(inkar$county_code)
# INKAR uses 8 digits, GERDA uses 5
inkar_codes_short <- unique(substr(inkar$county_code, 1, 5))

gerda_harm_codes <- unique(federal_cty_harm$county_code)
gerda_unharm_codes <- unique(federal_cty_unharm$county_code)

cat("\n--- Matching with harmonized data ---\n")
cat("INKAR counties (8 digits):", length(inkar_codes), "\n")
cat("INKAR counties (5 digits):", length(inkar_codes_short), "\n")
cat("GERDA harmonized counties:", length(gerda_harm_codes), "\n")

# Try direct match
overlap_direct <- intersect(inkar_codes, gerda_harm_codes)
cat("Direct match (8 digits):", length(overlap_direct), "\n")

# Try 5-digit match
overlap_short <- intersect(inkar_codes_short, gerda_harm_codes)
cat("Match (5 digits):", length(overlap_short), "\n")

# Counties in INKAR but not in GERDA
in_inkar_not_gerda <- setdiff(inkar_codes_short, gerda_harm_codes)
in_gerda_not_inkar <- setdiff(gerda_harm_codes, inkar_codes_short)

cat("\nCounties in INKAR but not GERDA (first 10):\n")
print(head(in_inkar_not_gerda, 10))

cat("\nCounties in GERDA but not INKAR (first 10):\n")
print(head(in_gerda_not_inkar, 10))

cat("\n=== TEST MERGE ===\n")
cat("Attempting to merge harmonized federal data with INKAR covariates...\n")

# Prepare INKAR data for merge (use 5-digit county code)
inkar_for_merge <- inkar |>
    mutate(county_code_5 = substr(county_code, 1, 5))

# Merge with federal harmonized data for overlapping years
test_merge <- federal_cty_harm |>
    filter(election_year %in% overlap_harm) |>
    left_join(
        inkar_for_merge,
        by = c("county_code" = "county_code_5", "election_year" = "year")
    )

# Check merge success
cat("\nMerge results:\n")
cat("  Total rows:", nrow(test_merge), "\n")
cat("  Rows with INKAR data:", sum(!is.na(test_merge$median_age)), "\n")
cat(
    "  Match rate:",
    round(100 * sum(!is.na(test_merge$median_age)) / nrow(test_merge), 1), "%\n"
)

# Show some matched data
cat("\nSample of merged data:\n")
test_merge |>
    select(
        county_code, election_year, state, turnout,
        share_65plus, unemployment_rate, median_income
    ) |>
    head(10) |>
    print()

cat("\n=== RECOMMENDATION ===\n")
cat("For merging INKAR covariates with GERDA election data:\n")
cat("1. Use 5-digit county codes (first 5 digits of INKAR codes)\n")
cat("2. Available years:", paste(overlap_harm, collapse = ", "), "\n")
cat(
    "3. Expected match rate: ~",
    round(100 * sum(!is.na(test_merge$median_age)) / nrow(test_merge), 1), "%\n"
)
