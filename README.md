# GERDA R Package

This package provides functions to access and work with GERDA datasets.

## Main Functions

- **`gerda_data_list()`**: This function lists all available GERDA datasets along with their descriptions, returning the data as a tibble.

- **`load_gerda_web(file_name, verbose = FALSE, file_format = "rds")`**: This function loads a GERDA dataset from a web source. It takes the following parameters:
  - `file_name`: The name of the dataset to load (see `gerda_data_list()` for available options).
  - `verbose`: If set to `TRUE`, it prints messages about the loading process (default is `FALSE`).
  - `file_format`: Specifies the format of the file to load, either "rds" or "csv" (default is "rds").

  The function checks for matches in the data dictionary, retrieves the corresponding data from a URL, and returns the dataset as a tibble.

## Usage Examples

```R
# List available datasets
available_data <- gerda_data_list()

# Load a dataset
data_municipal_harm <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")
```

## Note

For a complete list of available datasets and their descriptions, use the `gerda_data_list()` function.
