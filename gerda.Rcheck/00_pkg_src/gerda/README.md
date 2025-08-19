# GERDA R Package

This package provides tools to download comprehensive datasets of local, state, and federal election results in Germany from 1990 to 2021. The package facilitates access to data on turnout, vote shares for major parties, and demographic information across different levels of government.

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

## Note

For a complete list of available datasets and their descriptions, use the `gerda_data_list()` function. This function either prints a formatted table to the console and invisibly returns a tibble or directly returns the tibble without printing.

## Feedback

As this package is a work in progress, we welcome feedback. Please send your comments to <hhilbig@ucdavis.edu> or open an issue on the GitHub repository.
