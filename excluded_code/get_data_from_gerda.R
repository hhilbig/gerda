pacman::p_load(tidyverse)

covars_county <- "/Users/hanno/Documents/GitHub/german_election_data/data/covars_county/final"
covars_muni <- "/Users/hanno/Documents/GitHub/german_election_data/data/covars_municipality/final"
crosswalks <- "/Users/hanno/Documents/GitHub/german_election_data/data/crosswalks/final"
fed_elec <- "/Users/hanno/Documents/GitHub/german_election_data/data/federal_elections/"
muni_elec <- "/Users/hanno/Documents/GitHub/german_election_data/data/municipal_elections/final"
state_elec <- "/Users/hanno/Documents/GitHub/german_election_data/data/state_elections/final"
shapefiles <- "/Users/hanno/Documents/GitHub/german_election_data/data/shapefiles/final"

# For each of these, get a list of all files

covars_county_files <- list.files(covars_county, full.names = TRUE, recursive = TRUE)
covars_muni_files <- list.files(covars_muni, full.names = TRUE, recursive = TRUE)
crosswalks_files <- list.files(crosswalks, full.names = TRUE, recursive = TRUE)
fed_elec_files <- list.files(fed_elec, full.names = TRUE, recursive = TRUE) %>%
    str_subset("final")

muni_elec_files <- list.files(muni_elec, full.names = TRUE, recursive = TRUE) %>%
    str_subset("final")

state_elec_files <- list.files(state_elec, full.names = TRUE, recursive = TRUE)
shapefiles_files <- list.files(shapefiles, full.names = TRUE, recursive = TRUE)

# Combine all files into a single list
gerda_files <- c(
    covars_county_files, covars_muni_files, crosswalks_files,
    fed_elec_files, muni_elec_files, state_elec_files, shapefiles_files
)

# Separate csv and rds files
csv_files <- gerda_files[str_detect(gerda_files, "\\.csv$")]
rds_files <- gerda_files[str_detect(gerda_files, "\\.rds$")]

# Create directories for csv and rds files
dir.create("data/csv", recursive = TRUE, showWarnings = FALSE)
dir.create("data/rds", recursive = TRUE, showWarnings = FALSE)

# Function to check file size and copy if less than 100MB
copy_if_small <- function(from, to) {
    file_size <- file.size(from) / (1024 * 1024) # Convert to MB
    if (file_size < 100) {
        file.copy(from = from, to = to, overwrite = TRUE)
    } else {
        message(paste("Skipping", from, "- file size exceeds 100MB"))
    }
}

# Copy files to appropriate directories based on their extension and size
lapply(csv_files, function(file) copy_if_small(file, "data/csv"))
lapply(rds_files, function(file) copy_if_small(file, "data/rds"))

# Dictionary --------------------------------------------------------------

data_dictionary <- data.frame(
    data_name = c(
        "municipal_unharm", "municipal_harm", "state_unharm", "state_harm",
        "federal_muni_raw", "federal_muni_unharm", "federal_muni_harm",
        "federal_cty_unharm", "federal_cty_harm", "ags_crosswalks",
        "cty_crosswalks",
        "ags_area_pop_emp", "cty_area_pop_emp"
    ),
    description = c(
        "Local elections at the municipal level (1990–2020, unharmonized).",
        "Local elections at the municipal level (1990–2020, harmonized).",
        "State elections at the municipal level (2006–2019, unharmonized).",
        "State elections at the municipal level (2006–2019, harmonized).",
        "Federal elections at the municipal level (1980–2021, raw data).",
        "Federal elections at the municipal level (1980–2021, unharmonized).",
        "Federal elections at the municipal level (1990–2021, harmonized).",
        "Federal elections at the county level (1953–2021, unharmonized).",
        "Federal elections at the county level (1990–2021, harmonized).",
        "Crosswalks for municipalities (1990–2021).",
        "Crosswalks for counties (1990–2021).",
        "Crosswalk covariates (area, population, employment) for municipalities (1990–2021).",
        "Crosswalk covariates (area, population, employment) for counties (1990–2021)."
    ),
    csv_url = c(
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/municipal_elections/final/municipal_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/state_elections/final/state_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_raw.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/municipality_level/final/federal_muni_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_unharm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/federal_elections/county_level/final/federal_cty_harm.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/ags_crosswalks.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/crosswalks/final/cty_crosswalks.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_municipality/final/ags_area_pop_emp.csv?download=",
        "https://github.com/awiedem/german_election_data/raw/refs/heads/main/data/covars_county/final/cty_area_pop_emp.csv?download="
    )
)

# Save data dictionary

write_rds(data_dictionary, "data/data_dictionary.rds")
