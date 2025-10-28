# Test the new function-based covariate system

library(gerda)
library(dplyr)

devtools::load_all(".")

cat("=== Testing New Covariate Functions ===\n\n")

# Test 1: gerda_covariates()
cat("Test 1: gerda_covariates()\n")
covs <- gerda_covariates()
cat("  ✓ Dimensions:", nrow(covs), "x", ncol(covs), "\n")
cat("  ✓ Counties:", length(unique(covs$county_code)), "\n")
cat("  ✓ Years:", min(covs$year), "-", max(covs$year), "\n\n")

# Test 2: gerda_covariates_codebook()
cat("Test 2: gerda_covariates_codebook()\n")
codebook <- gerda_covariates_codebook()
cat("  ✓ Variables documented:", nrow(codebook), "\n")
cat("  ✓ Categories:", paste(unique(codebook$category), collapse = ", "), "\n\n")

# Test 3: add_gerda_covariates()
cat("Test 3: add_gerda_covariates()\n")
elections <- load_gerda_web("federal_cty_harm", verbose = FALSE)
cat("  Loaded elections:", nrow(elections), "rows\n")

merged <- add_gerda_covariates(elections)
cat("  ✓ Merged:", nrow(merged), "rows (same as elections!)\n")
cat("  ✓ New columns added:", ncol(merged) - ncol(elections), "\n")
cat("  ✓ Coverage (share_65plus):",
    sum(!is.na(merged$share_65plus)), "/", nrow(merged),
    "(", round(100 * sum(!is.na(merged$share_65plus)) / nrow(merged), 1), "%)\n\n")

# Test 4: Error handling
cat("Test 4: Error handling\n")
bad_data <- data.frame(x = 1:10)
tryCatch({
  add_gerda_covariates(bad_data)
  cat("  ✗ Should have raised error!\n")
}, error = function(e) {
  cat("  ✓ Correctly rejected data without county_code:", 
      conditionMessage(e), "\n")
})

cat("\n=== All tests passed! ===\n")

