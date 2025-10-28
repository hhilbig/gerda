rm(list = ls())

# Package development steps
if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
}

# Build documentation
message("Building documentation...")
devtools::document()

# Run checks
message("Running package checks...")
check_results <- devtools::check()

# Only build if checks pass
if (length(check_results$errors) == 0) {
    message("Building package...")
    devtools::build()
} else {
    stop("Package checks failed. Please fix errors before building.")
}

# Clean up .DS_Store files (macOS specific)
if (.Platform$OS.type == "unix") {
    message("Cleaning .DS_Store files...")
    system("find . -name '.DS_Store' -type f -delete")
}
