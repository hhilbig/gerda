## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(gerda)

## -----------------------------------------------------------------------------
gerda_data_list()

## ----eval=FALSE---------------------------------------------------------------
#  # Load the municipal harmonized dataset
#  municipal_harm_data <- load_gerda_web("municipal_harm", verbose = TRUE, file_format = "rds")

## -----------------------------------------------------------------------------
gerda_data_list()

## ----eval=FALSE---------------------------------------------------------------
#  federal_cty_harm <- load_gerda_web("federal_cty_harm", verbose = TRUE)

## ----eval=FALSE---------------------------------------------------------------
#  # Map GERDA party names to left-right positions
#  parties <- c("cdu", "spd", "linke_pds", "fdp")
#  left_right_scores <- party_crosswalk(parties, "left_right")
#  print(left_right_scores)
#  
#  # Map to English party names
#  english_names <- party_crosswalk(parties, "party_name_english")
#  print(english_names)

