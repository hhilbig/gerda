# GERDA R Package

This package provides tools to download comprehensive datasets of local, state, and federal election results in Germany from 1990 to 2025. The package facilitates access to data on turnout, vote shares for major parties, and demographic information across different levels of government. The package also includes county-level socioeconomic covariates from INKAR, municipality-level data from the German Census 2022, and a party crosswalk mapping GERDA party names to ParlGov attributes.

GERDA was compiled by Vincent Heddesheimer, Florian Sichart, Andreas Wiedemann and Hanno Hilbig. For additional information, see the GERDA website (www.german-elections.com) and the accompanying publication: [doi.org/10.1038/s41597-025-04811-5](https://doi.org/10.1038/s41597-025-04811-5)

**Note: This package is currently a work in progress. Comments and suggestions are welcome -- please send to <hhilbig@ucdavis.edu>.**

## Installation

You can install GERDA from CRAN:

```R
install.packages("gerda")
```

Or install the development version from GitHub:

```R
# Install devtools if you haven't already
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install GERDA development version
devtools::install_github("hhilbig/gerda")
```

## Main Functions

- **`gerda_data_list(print_table = TRUE)`**: Lists all available GERDA datasets along with their descriptions. Parameters:
  - `print_table`: If `TRUE` (default), prints a formatted table to the console and invisibly returns a tibble. If `FALSE`, directly returns the tibble without printing.

- **`load_gerda_web(file_name, verbose = FALSE, file_format = "rds")`**: This function loads a GERDA dataset from a web source. It takes the following parameters:
  - `file_name`: The name of the dataset to load (see `gerda_data_list()` for available options).
  - `verbose`: If set to `TRUE`, it prints messages about the loading process (default is `FALSE`).
  - `file_format`: Specifies the format of the file to load, either "rds" or "csv" (default is "rds"). Both formats return the same tibble, so this choice only affects download size and speed.

  The function includes fuzzy matching for file names and will suggest close matches if an exact match isn't found.

- **`party_crosswalk(party_gerda, destination)`**: Maps party names to their corresponding values from the ParlGov database. For a vector of party names, it returns a vector of the same length with the corresponding values from the destination column. Parameters:
  - `party_gerda`: A character vector of party names using GERDA's naming scheme
  - `destination`: The name of the column from ParlGov's view_party table to map to (e.g., "left_right" for ideology scores)

## Usage Examples

```R
# Load the package
library(gerda)

# List available datasets
available_data <- gerda_data_list()

# Load a dataset
data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")
```

## County-Level Covariates

The package provides access to socioeconomic and demographic indicators for 400 German counties (1995-2022) from INKAR. INKAR data is available from 1995 to 2022, so covariates can be matched to federal elections from 1998 onwards (earlier elections fall outside the INKAR coverage window). These can be easily added to both county-level and municipal-level GERDA election data:

```R
library(gerda)
library(dplyr)

# Works with county-level data
county_merged <- load_gerda_web("federal_cty_harm") %>%
  add_gerda_covariates()

# Also works with municipal-level data
# (Note: All municipalities in the same county get identical covariate values)
muni_merged <- load_gerda_web("federal_muni_harm_21") %>%
  add_gerda_covariates()

# Done! Your data now includes 30 county-level covariates
```

For more control, use the accessor functions:

```R
# Get raw covariate data
covs <- gerda_covariates()

# View the codebook
codebook <- gerda_covariates_codebook()

# Manual merge (advanced)
merged <- elections %>%
  left_join(covs, by = c("county_code" = "county_code", "election_year" = "year"))
```

The dataset includes 30 variables covering:

- **Demographics**: Age structure, foreign population, gender
- **Economy**: GDP, sectoral composition, enterprise structure
- **Labor Market**: Unemployment rates (overall, youth, long-term)
- **Education**: School completion rates, students, apprentices
- **Income**: Purchasing power, low-income households
- **Healthcare**: Physician density, hospital beds, GP density
- **Childcare**: Coverage rates for under-3 and 3-6 age groups
- **Housing**: Building permits, rent levels, living space
- **Transport**: Cars per capita
- **Public Finances**: Municipal debt, tax revenue

**Coverage note:** Core variables (demographics, economy, labor market) are available for all election years 1998-2021. Some newer INKAR indicators are available for recent elections only. Check `gerda_covariates_codebook()` for per-variable coverage details.

See `?gerda_covariates` for full documentation and `gerda_covariates_codebook()` for a complete data dictionary with variable descriptions, units, and missing data information.

## Census 2022 Data

The package also provides municipality-level data from the German Census 2022 (Zensus 2022). This cross-sectional snapshot covers approximately 10,800 municipalities and can be merged with any GERDA election dataset. The main advantage of this data is that it is observed at the municipal level (unlike the county-level INKAR data), allowing for more fine-grained analyses of local election outcomes. However, the census is a single time point (2022), so it does not vary across election years -- users should not conduct analyses that rely on over-time variation in these covariates.

```R
library(gerda)

# Add census data to municipal-level elections
muni_merged <- load_gerda_web("federal_muni_harm_21") |>
  add_gerda_census()

# Also works with county-level data (aggregated from municipalities)
county_merged <- load_gerda_web("federal_cty_harm") |>
  add_gerda_census()
```

The census data includes 14 indicators across four categories:

- **Demographics**: Population, age structure (under 18, 18-29, 30-49, 50-64, 65+)
- **Migration**: Migration background share, foreign nationals share
- **Households**: Average household size
- **Housing**: Total dwellings, vacancy rate, ownership rate, average rent per m², single-family home share

Since the census is a 2022 snapshot, the same values are attached to all election years.

**Coverage note:** Most census variables have >95% municipality coverage. `avg_household_size_census22` has approximately 12.5% missing values due to Destatis disclosure rules that suppress data for small municipalities.

See `?gerda_census` for full documentation and `gerda_census_codebook()` for the complete data dictionary.

## Note

For a complete list of available datasets and their descriptions, use the `gerda_data_list()` function. This function either prints a formatted table to the console and invisibly returns a tibble or directly returns the tibble without printing.

## Feedback

As this package is a work in progress, we welcome feedback. Please send your comments to <hhilbig@ucdavis.edu> or open an issue on the GitHub repository.
