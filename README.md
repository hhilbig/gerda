GERDA R Package

- **`gerda_data_list()`**: This function lists all available GERDA datasets along with their descriptions, returning the data as a tibble.

- **`load_gerda_web(file_name, verbose = FALSE)`**: This function loads a GERDA dataset from a web source. It takes the dataset name as input, checks for matches in the data dictionary, and retrieves the corresponding data from a URL. If `verbose` is set to `TRUE`, it prints messages about the loading process.
