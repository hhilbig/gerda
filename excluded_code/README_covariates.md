# County-Level Covariates from INKAR

This directory contains scripts for downloading and processing county-level covariates from INKAR (Indikatoren und Karten zur Raum- und Stadtentwicklung).

## Data Source

Data are downloaded from [INKAR](https://www.inkar.de/) using the [`{inkr}` R package](https://regiohub.github.io/inkr/).

**Citation:**

- Nguyen HL (2024). {inkr}: Local Access from R to All INKAR Data. <https://doi.org/10.5281/zenodo.7643755>
- Data provided by: Bundesinstitut für Bau-, Stadt- und Raumforschung (BBSR)
- License: Data licence Germany – attribution – version 2.0

## Files

### Scripts (in `excluded_code/`)

- `download_main_county_covariates.R` - Main script to download 20 key county-level indicators
- `explore_inkar_indicators.R` - Exploration script to browse available indicators
- `main_indicators_list.txt` - Documentation of selected indicators

### Data (in `data_not_used/`)

- `rds/inkar_county_covariates.rds` - Processed covariates in RDS format
- `csv/inkar_county_covariates.csv` - Processed covariates in CSV format

## Data Structure

### Coverage

- **Spatial**: 400 German counties (Kreise)
- **Temporal**: 1995-2022
- **Observations**: 11,200 (400 counties × 28 years)

### Variables (20 covariates)

#### Demographics (4 variables)

- `share_65plus` - Share of population aged 65+
- `median_age` - Median age of population
- `share_foreign` - Share of foreign population
- `share_female` - Share of female population

#### Economy (6 variables)

- `gdp_per_capita` - GDP per capita (Bruttoinlandsprodukt je Einwohner)
- `share_primary_sector` - Primary sector share of gross value added
- `share_secondary_sector` - Secondary sector share of gross value added
- `share_tertiary_sector` - Tertiary sector share of gross value added
- `share_micro_enterprises` - Share of micro enterprises
- `share_large_enterprises` - Share of large enterprises

#### Labor Market (3 variables)

- `unemployment_rate` - Unemployment rate (Arbeitslosenquote)
- `share_longterm_unemployed` - Share of long-term unemployed
- `youth_unemployment_rate` - Youth unemployment rate (under 25)

#### Education (4 variables)

- `share_abitur` - Share of school leavers with Abitur (university entrance qualification)
- `share_no_degree` - Share of school leavers without any degree
- `students_per_100` - University students per 100 residents aged 18-25
- `apprentices_per_100` - Apprentices per 100 residents aged 15-25

#### Income (3 variables)

- `median_income` - Median income (Medianeinkommen)
- `purchasing_power` - Purchasing power (Kaufkraft)
- `share_low_income_hh` - Share of low-income households

## Usage

### Download/Update Data

To download or update the data, run:

```R
source("excluded_code/download_main_county_covariates.R")
```

**Note**: First-time use requires building the local INKAR database, which may take several minutes.

### Load Data

```R
# Load RDS
county_covariates <- readRDS("data_not_used/rds/inkar_county_covariates.rds")

# Or load CSV
county_covariates <- read.csv("data_not_used/csv/inkar_county_covariates.csv")
```

### Merge with Election Data

To merge with GERDA election data, use the county code:

```R
library(gerda)
library(dplyr)

# Load federal election data at county level
elections <- load_gerda_web("federal_cty_harm")

# Load covariates
covariates <- readRDS("data_not_used/rds/inkar_county_covariates.rds")

# Merge (adjust county code format if needed)
merged <- elections |>
  left_join(covariates, by = c("county_code_21" = "county_code", "year" = "year"))
```

## Missing Data

Some variables have missing values, particularly for earlier years or specific indicators:

- Basic demographics (age, foreign population): Complete data
- Economic indicators: Some missingness, especially in earlier years
- Income variables: More limited coverage (particularly median_income and purchasing_power)

See the data summary for detailed missingness patterns.

## Data Quality Notes

1. County codes follow the 2021 boundaries (AGS format with 8 digits)
2. Some administrative reforms may affect data comparability over time
3. Economic data (GDP, sector composition) may have breaks in series
4. Income data availability varies by year and county

## Extending the Data

To add more INKAR indicators:

1. Explore available indicators:

   ```R
   source("excluded_code/explore_inkar_indicators.R")
   ```

2. Modify `download_main_county_covariates.R` to include additional variables

3. See the [inkr documentation](https://regiohub.github.io/inkr/) for available indicators

## Branch Information

These covariates were added in the `covariate-branch` branch. They are stored in `data_not_used/` and are not part of the CRAN package, but can be used for research purposes.
