# Create codebook for county_covariates dataset

library(tibble)
library(dplyr)
library(tidyr)

cat("=== Creating codebook for county_covariates ===\n\n")

# Create the codebook as a tibble
covariates_codebook <- tibble::tribble(
    ~variable,                    ~label,                                                      ~unit,           ~category,      ~inkar_code,        ~notes,
    "county_code",                "County code (Kreisschlüssel)",                              "5-digit AGS",   "ID",           NA,                 "Matches GERDA county codes (2021 boundaries)",
    "year",                       "Year of observation",                                       "year",          "ID",           NA,                 "Annual data from 1995-2022",

    # Demographics
    "share_65plus",               "Share of population aged 65 and older",                     "percent",       "Demographics", "a_bev65um",        "Proportion of elderly population",
    "median_age",                 "Median age of population",                                  "years",         "Demographics", "m_bev_alter",      "Median age in years",
    "share_foreign",              "Share of foreign population",                               "percent",       "Demographics", "a_ausl_bev",       "Non-German nationals",
    "share_female",               "Share of female population",                                "percent",       "Demographics", "a_bevf",           "Gender composition",

    # Economy
    "gdp_per_capita",             "GDP per capita",                                            "euros",         "Economy",      "q_bip_ew",         "Bruttoinlandsprodukt je Einwohner",
    "share_primary_sector",       "Primary sector share of gross value added",                 "percent",       "Economy",      "a_bws_1sektor",    "Agriculture, forestry, fishing",
    "share_secondary_sector",     "Secondary sector share of gross value added",               "percent",       "Economy",      "a_bws_2sektor",    "Manufacturing, construction",
    "share_tertiary_sector",      "Tertiary sector share of gross value added",                "percent",       "Economy",      "a_bws_3sektor",    "Services",
    "share_micro_enterprises",    "Share of micro enterprises",                                "percent",       "Economy",      "a_betr_kleinst",   "Enterprises with <10 employees",
    "share_large_enterprises",    "Share of large enterprises",                                "percent",       "Economy",      "a_betr_groß",      "Enterprises with ≥250 employees",

    # Labor Market
    "unemployment_rate",          "Unemployment rate",                                         "percent",       "Labor Market", "q_alo",            "Arbeitslosenquote",
    "share_longterm_unemployed",  "Share of long-term unemployed",                             "percent",       "Labor Market", "a_aloLang",        "Unemployed >12 months as % of all unemployed",
    "youth_unemployment_rate",    "Youth unemployment rate (under 25)",                        "percent",       "Labor Market", "q_alo_u25",        "Unemployment rate for ages <25",

    # Education
    "share_abitur",               "Share of school leavers with Abitur",                       "percent",       "Education",    "a_schul_abi",      "University entrance qualification",
    "share_no_degree",            "Share of school leavers without any degree",                "percent",       "Education",    "a_schul_oA",       "School leavers without qualification",
    "students_per_100",           "University students per 100 residents aged 18-25",          "per 100",       "Education",    "q_stud_1825",      "Higher education enrollment",
    "apprentices_per_100",        "Apprentices per 100 residents aged 15-25",                  "per 100",       "Education",    "q_azubi_1525",     "Vocational training enrollment",

    # Income
    "median_income",              "Median income",                                             "euros",         "Income",       "m_ek",             "Medianeinkommen der sozialversicherungspflichtig Beschäftigten",
    "purchasing_power",           "Purchasing power",                                          "euros",         "Income",       "q_kaufkraft",      "Kaufkraft je Einwohner",
    "share_low_income_hh",        "Share of low-income households",                            "percent",       "Income",       "a_hheink_niedrig", "Households with income <60% of median"
)

# Display the codebook
cat("Codebook created with", nrow(covariates_codebook), "variables\n\n")

cat("=== Preview ===\n")
print(covariates_codebook, n = 25)

cat("\n=== Variables by category ===\n")
table(covariates_codebook$category) %>% print()

cat("\n=== Missing data patterns (from actual data) ===\n")
data <- readRDS("data_not_used/rds/inkar_county_covariates.rds")
missing_info <- data %>%
    select(-county_code, -county_name, -year) %>%
    summarise(across(everything(), ~ sum(is.na(.)))) %>%
    tidyr::pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
    mutate(
        total_obs = 11200,
        missing_pct = round(100 * missing_count / total_obs, 1)
    ) %>%
    arrange(desc(missing_count))

print(missing_info, n = 25)

# Add missing info to codebook
covariates_codebook <- covariates_codebook %>%
    left_join(
        missing_info %>% select(variable, missing_pct),
        by = "variable"
    )

# Save the codebook
cat("\n=== Saving ===\n")
save(covariates_codebook, file = "data_not_used/covariates_codebook.rda", compress = "xz")
cat("✓ Saved to data_not_used/covariates_codebook.rda\n")

# Also save as CSV for easy viewing
write.csv(covariates_codebook, "data_not_used/csv/covariates_codebook.csv", row.names = FALSE)
cat("✓ Saved to data_not_used/csv/covariates_codebook.csv\n")

cat("\n=== Next steps ===\n")
cat("1. Copy data_not_used/covariates_codebook.rda to data/\n")
cat("2. Create R/covariates_codebook.R with documentation\n")
cat("3. Run devtools::document()\n")
