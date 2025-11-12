# GERDA R Package

This package provides tools to download comprehensive datasets of local, state, and federal election results in Germany from 1990 to 2025. The package facilitates access to data on turnout, vote shares for major parties, and demographic information across different levels of government.

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
  - `file_format`: Specifies the format of the file to load, either "rds" or "csv" (default is "rds").

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

The package provides access to socioeconomic and demographic indicators for 400 German counties (1995-2022) from INKAR. These can be easily added to both county-level and municipal-level GERDA election data:

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

# Done! Your data now includes 20 county-level covariates
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

The dataset includes 20 variables covering:

- **Demographics**: Age structure, foreign population, gender
- **Economy**: GDP, sectoral composition, enterprise structure
- **Labor market**: Unemployment rates (overall, youth, long-term)
- **Education**: School completion rates, students, apprentices
- **Income**: Median income, purchasing power, low-income households

See `?gerda_covariates` for full documentation and `gerda_covariates_codebook()` for a complete data dictionary with variable descriptions, units, and missing data information.

## Note

For a complete list of available datasets and their descriptions, use the `gerda_data_list()` function. This function either prints a formatted table to the console and invisibly returns a tibble or directly returns the tibble without printing.

## Feedback

As this package is a work in progress, we welcome feedback. Please send your comments to <hhilbig@ucdavis.edu> or open an issue on the GitHub repository.
