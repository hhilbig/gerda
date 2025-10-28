source("R/load_gerda_web.R")

library(tidyverse)

data_name <- c(
    "municipal_unharm", "municipal_harm", "state_unharm", "state_harm",
    "federal_muni_raw", "federal_muni_unharm", "federal_muni_harm",
    "federal_cty_unharm", "federal_cty_harm", "ags_crosswalks",
    "cty_crosswalks", "ags_area_pop_emp", "cty_area_pop_emp"
)

# Test both CSV and RDS URLs for each dataset
test_results <- lapply(data_name, function(x) {
    cat("Testing", x, "\n")
    csv_result <- tryCatch(
        {
            load_gerda_web(file_name = x, file_format = "csv", verbose = TRUE)
            "Success"
        },
        error = function(e) paste("Error:", e$message)
    )

    rds_result <- tryCatch(
        {
            load_gerda_web(file_name = x, file_format = "rds", verbose = TRUE)
            "Success"
        },
        error = function(e) paste("Error:", e$message)
    )

    list(
        dataset = x,
        csv = csv_result,
        rds = rds_result
    )
})


# Print results in a readable format
cat("\nURL Test Results:\n")
lapply(test_results, function(x) {
    cat("\nDataset:", x$dataset, "\n")
    cat("CSV:", x$csv, "\n")
    cat("RDS:", x$rds, "\n")
})
