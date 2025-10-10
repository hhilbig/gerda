# Download main county-level covariates from INKAR
# This script downloads 20 key indicators commonly used in electoral research

library(dplyr)
library(tidyr)

# Install inkr if needed
if (!requireNamespace("inkr", quietly = TRUE)) {
    remotes::install_github("RegioHub/inkr")
}

library(inkr)

cat("Downloading county-level covariates from INKAR...\n\n")

# =============================================================================
# DEMOGRAPHICS (from bevoelkerung table)
# =============================================================================
cat("1. Downloading demographics...\n")
demographics <- inkar$bevoelkerung |>
    filter(raumbezug == "Kreise") |>
    select(
        kennziffer, name, zeitbezug,
        a_bev65um, # Share population 65+
        m_bev_alter, # Median age
        a_ausl_bev, # Share foreign population
        a_bevf # Share female population
    ) |>
    collect() |>
    rename(
        county_code = kennziffer,
        county_name = name,
        year = zeitbezug,
        share_65plus = a_bev65um,
        median_age = m_bev_alter,
        share_foreign = a_ausl_bev,
        share_female = a_bevf
    ) |>
    mutate(year = as.numeric(year))

# =============================================================================
# ECONOMY (from wirtschaft table)
# =============================================================================
cat("2. Downloading economic indicators...\n")
economy <- inkar$wirtschaft |>
    filter(raumbezug == "Kreise") |>
    collect() |>
    select(
        kennziffer, name, zeitbezug,
        q_bip_ew, # GDP per capita
        a_bws_1sektor, # Primary sector share
        a_bws_2sektor, # Secondary sector share
        a_bws_3sektor, # Tertiary sector share
        a_betr_kleinst, # Micro enterprises share
        matches("a_betr_gro") # Large enterprises share (handles encoding)
    ) |>
    rename(
        county_code = kennziffer,
        county_name = name,
        year = zeitbezug,
        gdp_per_capita = q_bip_ew,
        share_primary_sector = a_bws_1sektor,
        share_secondary_sector = a_bws_2sektor,
        share_tertiary_sector = a_bws_3sektor,
        share_micro_enterprises = a_betr_kleinst
    ) |>
    rename_with(~"share_large_enterprises", matches("a_betr_gro")) |>
    mutate(year = as.numeric(year))

# =============================================================================
# UNEMPLOYMENT (from arbeitslosigkeit table)
# =============================================================================
cat("3. Downloading unemployment indicators...\n")
unemployment <- inkar$arbeitslosigkeit |>
    filter(raumbezug == "Kreise") |>
    collect() |>
    select(
        kennziffer, name, zeitbezug,
        q_alo, # Unemployment rate
        a_aloLang, # Long-term unemployed share
        q_alo_u25 # Youth unemployment rate
    ) |>
    rename(
        county_code = kennziffer,
        county_name = name,
        year = zeitbezug,
        unemployment_rate = q_alo,
        share_longterm_unemployed = a_aloLang,
        youth_unemployment_rate = q_alo_u25
    ) |>
    mutate(year = as.numeric(year))

# =============================================================================
# EDUCATION (from bildung table)
# =============================================================================
cat("4. Downloading education indicators...\n")
education <- inkar$bildung |>
    filter(raumbezug == "Kreise") |>
    select(
        kennziffer, name, zeitbezug,
        a_schul_abi, # High school graduates (Abitur)
        a_schul_oA, # School leavers without qualification
        q_stud_1825, # University students per 100 residents 18-25
        q_azubi_1525 # Apprentices per 100 residents 15-25
    ) |>
    collect() |>
    rename(
        county_code = kennziffer,
        county_name = name,
        year = zeitbezug,
        share_abitur = a_schul_abi,
        share_no_degree = a_schul_oA,
        students_per_100 = q_stud_1825,
        apprentices_per_100 = q_azubi_1525
    ) |>
    mutate(year = as.numeric(year))

# =============================================================================
# INCOME (from privateinkommen_und_private_schulden table)
# =============================================================================
cat("5. Downloading income indicators...\n")
income <- inkar$privateinkommen_und_private_schulden |>
    filter(raumbezug == "Kreise") |>
    select(
        kennziffer, name, zeitbezug,
        m_ek, # Median income
        q_kaufkraft, # Purchasing power
        a_hheink_niedrig # Low income households share
    ) |>
    collect() |>
    rename(
        county_code = kennziffer,
        county_name = name,
        year = zeitbezug,
        median_income = m_ek,
        purchasing_power = q_kaufkraft,
        share_low_income_hh = a_hheink_niedrig
    ) |>
    mutate(year = as.numeric(year))

# =============================================================================
# MERGE ALL INDICATORS
# =============================================================================
cat("6. Merging all indicators...\n")

county_covariates <- demographics |>
    left_join(economy, by = c("county_code", "county_name", "year")) |>
    left_join(unemployment, by = c("county_code", "county_name", "year")) |>
    left_join(education, by = c("county_code", "county_name", "year")) |>
    left_join(income, by = c("county_code", "county_name", "year")) |>
    arrange(county_code, year)

# =============================================================================
# SUMMARY AND SAVE
# =============================================================================
cat("\n=== SUMMARY ===\n")
cat("Total rows:", nrow(county_covariates), "\n")
cat("Counties:", length(unique(county_covariates$county_code)), "\n")
cat(
    "Year range:", min(county_covariates$year, na.rm = TRUE), "-",
    max(county_covariates$year, na.rm = TRUE), "\n"
)
cat("\nVariable names:\n")
print(names(county_covariates))

cat("\n=== First few rows ===\n")
print(head(county_covariates, 10))

# Save as RDS
cat("\nSaving to data_not_used/rds/inkar_county_covariates.rds...\n")
saveRDS(county_covariates, "data_not_used/rds/inkar_county_covariates.rds")

# Save as CSV
cat("Saving to data_not_used/csv/inkar_county_covariates.csv...\n")
write.csv(county_covariates, "data_not_used/csv/inkar_county_covariates.csv",
    row.names = FALSE
)

cat("\n✓ Done! Data saved successfully.\n")
