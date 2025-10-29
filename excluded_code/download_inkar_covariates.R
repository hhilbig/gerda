# Download and process INKAR county-level covariates
# This script downloads data from INKAR using the {inkr} package,
# cleans it, and saves it for use in the GERDA package.

library(dplyr)
library(tidyr)

# Install inkr if needed
if (!requireNamespace("inkr", quietly = TRUE)) {
    remotes::install_github("RegioHub/inkr")
}

library(inkr)

# Build local INKAR database (only needs to be done once)
# Uncomment the line below on first run:
# inkar_db_build()

# Example: Download median income data at county level
# You can modify this to get other indicators

# First, explore available indicators
# inkar$`_indikatoren` |>
#   filter(grepl("Einkommen|income", name, ignore.case = TRUE)) |>
#   select(merk_id, kurzname, name) |>
#   collect()

# Download county-level data
# This is just an example - modify based on what covariates you need
county_covariates <- inkar$privateinkommen_und_private_schulden |>
    filter(raumbezug == "Kreise") |>
    select(kennung, name, zeitbezug, m_ek) |>
    collect() |>
    rename(
        county_code = kennung,
        county_name = name,
        year = zeitbezug,
        median_income = m_ek
    )

# Preview the data
head(county_covariates)
summary(county_covariates)

# Save as RDS
saveRDS(county_covariates, "data_not_used/rds/inkar_county_covariates.rds")

# Save as CSV
write.csv(county_covariates, "data_not_used/csv/inkar_county_covariates.csv",
    row.names = FALSE
)

cat("Data saved to data_not_used/\n")
