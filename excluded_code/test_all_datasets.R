#!/usr/bin/env Rscript

# Test script for all GERDA datasets
# This script tests loading all datasets from gerda_data_list()

# Load required packages
suppressPackageStartupMessages({
    library(gerda)
    library(dplyr)
    library(testthat)
})

cat("Testing all GERDA datasets...\n")
cat("=============================\n\n")

# Get list of all available datasets
available_datasets <- gerda_data_list(print_table = FALSE)
dataset_names <- available_datasets$data_name

cat("Found", length(dataset_names), "datasets to test:\n")
cat(paste(dataset_names, collapse = ", "), "\n\n")

# Initialize results tracking
results <- data.frame(
    dataset = character(),
    format = character(),
    success = logical(),
    error_message = character(),
    rows = integer(),
    cols = integer(),
    stringsAsFactors = FALSE
)

# Test each dataset in both formats
for (dataset in dataset_names) {
    cat("Testing dataset:", dataset, "\n")
    cat("----------------------------------------\n")

    # Test RDS format
    cat("  Testing RDS format... ")
    tryCatch(
        {
            data_rds <- load_gerda_web(dataset, file_format = "rds", verbose = FALSE)
            if (!is.null(data_rds)) {
                results <- rbind(results, data.frame(
                    dataset = dataset,
                    format = "rds",
                    success = TRUE,
                    error_message = "",
                    rows = nrow(data_rds),
                    cols = ncol(data_rds),
                    stringsAsFactors = FALSE
                ))
                cat("✓ SUCCESS (", nrow(data_rds), "rows,", ncol(data_rds), "cols)\n")
            } else {
                results <- rbind(results, data.frame(
                    dataset = dataset,
                    format = "rds",
                    success = FALSE,
                    error_message = "Returned NULL",
                    rows = 0,
                    cols = 0,
                    stringsAsFactors = FALSE
                ))
                cat("✗ FAILED (Returned NULL)\n")
            }
        },
        error = function(e) {
            results <<- rbind(results, data.frame(
                dataset = dataset,
                format = "rds",
                success = FALSE,
                error_message = as.character(e$message),
                rows = 0,
                cols = 0,
                stringsAsFactors = FALSE
            ))
            cat("✗ FAILED (", e$message, ")\n")
        }
    )

    # Test CSV format
    cat("  Testing CSV format... ")
    tryCatch(
        {
            data_csv <- load_gerda_web(dataset, file_format = "csv", verbose = FALSE)
            if (!is.null(data_csv)) {
                results <- rbind(results, data.frame(
                    dataset = dataset,
                    format = "csv",
                    success = TRUE,
                    error_message = "",
                    rows = nrow(data_csv),
                    cols = ncol(data_csv),
                    stringsAsFactors = FALSE
                ))
                cat("✓ SUCCESS (", nrow(data_csv), "rows,", ncol(data_csv), "cols)\n")
            } else {
                results <- rbind(results, data.frame(
                    dataset = dataset,
                    format = "csv",
                    success = FALSE,
                    error_message = "Returned NULL",
                    rows = 0,
                    cols = 0,
                    stringsAsFactors = FALSE
                ))
                cat("✗ FAILED (Returned NULL)\n")
            }
        },
        error = function(e) {
            results <<- rbind(results, data.frame(
                dataset = dataset,
                format = "csv",
                success = FALSE,
                error_message = as.character(e$message),
                rows = 0,
                cols = 0,
                stringsAsFactors = FALSE
            ))
            cat("✗ FAILED (", e$message, ")\n")
        }
    )

    cat("\n")
}

# Summary
cat("SUMMARY\n")
cat("=======\n")
total_tests <- nrow(results)
successful_tests <- sum(results$success)
failed_tests <- total_tests - successful_tests

cat("Total tests:", total_tests, "\n")
cat("Successful:", successful_tests, "\n")
cat("Failed:", failed_tests, "\n")
cat("Success rate:", round(successful_tests / total_tests * 100, 1), "%\n\n")

if (failed_tests > 0) {
    cat("FAILED TESTS:\n")
    cat("=============\n")
    failed_results <- results[!results$success, ]
    for (i in 1:nrow(failed_results)) {
        row <- failed_results[i, ]
        cat("-", row$dataset, "(", row$format, "):", row$error_message, "\n")
    }
    cat("\n")
}

# Check for consistency between RDS and CSV formats
cat("FORMAT CONSISTENCY CHECK:\n")
cat("=========================\n")
consistency_issues <- 0

for (dataset in dataset_names) {
    rds_result <- results[results$dataset == dataset & results$format == "rds", ]
    csv_result <- results[results$dataset == dataset & results$format == "csv", ]

    if (nrow(rds_result) == 1 && nrow(csv_result) == 1 &&
        rds_result$success && csv_result$success) {
        if (rds_result$rows != csv_result$rows || rds_result$cols != csv_result$cols) {
            cat("⚠️  Inconsistent dimensions for", dataset, ":\n")
            cat("   RDS:", rds_result$rows, "rows,", rds_result$cols, "cols\n")
            cat("   CSV:", csv_result$rows, "rows,", csv_result$cols, "cols\n")
            consistency_issues <- consistency_issues + 1
        }
    }
}

if (consistency_issues == 0) {
    cat("✓ All successful datasets have consistent dimensions between RDS and CSV formats\n")
} else {
    cat("⚠️  Found", consistency_issues, "datasets with inconsistent dimensions\n")
}

cat("\nTest completed!\n")

# Save results to file
write.csv(results, "dataset_test_results.csv", row.names = FALSE)
cat("Detailed results saved to: dataset_test_results.csv\n")

