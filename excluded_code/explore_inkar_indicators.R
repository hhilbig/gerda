# Explore INKAR indicators to identify main covariates
# This script helps identify the most relevant indicators for county-level analysis

library(dplyr)
library(tidyr)

# Install inkr if needed
if (!requireNamespace("inkr", quietly = TRUE)) {
    remotes::install_github("RegioHub/inkr")
}

library(inkr)

# Build local INKAR database (only needs to be done once)
cat("Building INKAR database (this may take a few minutes)...\n")
inkar_db_build()

# Explore available indicators by category
cat("=== Available indicator categories ===\n")
inkar$`_indikatoren` |>
    count(bereich, sort = TRUE) |>
    collect() |>
    print(n = Inf)

cat("\n=== Exploring key indicators ===\n\n")

# Economy indicators
cat("--- WIRTSCHAFT (Economy) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Wirtschaft") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Labor market
cat("\n--- ARBEITSLOSIGKEIT (Unemployment) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Arbeitslosigkeit") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Education
cat("\n--- BILDUNG (Education) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Bildung") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Population
cat("\n--- BEVÖLKERUNG (Population) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Bevölkerung") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Income
cat("\n--- PRIVATEINKOMMEN (Private Income) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Privateinkommen und private Schulden") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Employment
cat("\n--- BESCHÄFTIGUNG (Employment) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Beschäftigung und Erwerbstätigkeit") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Public finances
cat("\n--- ÖFFENTLICHE FINANZEN (Public Finances) ---\n")
inkar$`_indikatoren` |>
    filter(bereich == "Öffentliche Finanzen") |>
    select(kuerzel, kurzname, name) |>
    collect() |>
    print(n = Inf)

# Check what spatial levels are available
cat("\n=== Available spatial levels (Raumbezug) ===\n")
inkar$`_regionen` |>
    distinct(raumbezug) |>
    arrange(raumbezug) |>
    collect() |>
    print(n = Inf)
