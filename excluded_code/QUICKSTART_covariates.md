# Quick Start: Adding County Covariates to GERDA Data

## Minimal Example (Recommended)

```r
library(gerda)
library(dplyr)

# Works with county-level data
county_data <- load_gerda_web("federal_cty_harm") %>%
  add_gerda_covariates()

# Also works with municipal-level data
muni_data <- load_gerda_web("federal_muni_harm_21") %>%
  add_gerda_covariates()

# Done! Your data is ready.
```

That's it! The `merged` dataset now contains all election results with covariates.

The `add_gerda_covariates()` function automatically:

- Works with both county and municipal data
- Auto-detects data level and uses correct join keys
- Keeps only election years (left join)
- Prevents common merge errors

**Note**: Covariates are at the county level. When merging with municipal data, all municipalities within the same county will have identical covariate values.

---

## Alternative: Manual Merge (Advanced Users)

If you need more flexibility, use the accessor functions:

```r
library(gerda)
library(dplyr)

# 1. Get the covariates data
covs <- gerda_covariates()

# 2. Inspect before merging
head(covs)
summary(covs$unemployment_rate)

# 3. Manual merge with custom join
merged <- elections %>%
  inner_join(covs, by = c("county_code" = "county_code", "election_year" = "year"))
```

---

## More Details

### What covariates are available?

```r
# View the codebook
codebook <- gerda_covariates_codebook()
print(codebook)

# By category
codebook %>% filter(category == "Demographics")

# Variables with good coverage
codebook %>% filter(missing_pct < 10)
```

### What years are covered?

- **Election data**: 1990, 1994, 1998, 2002, 2005, 2009, 2013, 2017, 2021
- **Covariates**: 1995-2022 (annual)
- **Overlap**: Elections from 1998 onwards have covariate data

### Which variables should I use?

**Best coverage (always available):**

- `share_65plus` - Age structure
- `median_age` - Median age
- `share_foreign` - Foreign population share
- `share_female` - Gender composition
- `share_longterm_unemployed` - Long-term unemployment

**Good coverage (>75%):**

- `unemployment_rate` - Overall unemployment
- `share_abitur` - High school completion rate
- `gdp_per_capita` - GDP per capita

**Limited coverage (mostly recent years):**

- `median_income` - Median income (only 2020-2021)
- `purchasing_power` - Purchasing power
- Youth unemployment, sector composition

### Example Analysis

```r
# Unemployment and AfD vote (2021)
merged %>%
  filter(election_year == 2021) %>%
  filter(!is.na(unemployment_rate)) %>%
  ggplot(aes(unemployment_rate, afd)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(
    x = "Unemployment Rate (%)",
    y = "AfD Vote Share",
    title = "Unemployment and AfD Support (2021)"
  )
```

---

## Full Workflow

See `excluded_code/workflow_add_covariates.R` for a complete step-by-step tutorial with:

- Data exploration
- Merge quality checks
- Missing data analysis
- Example analyses
- Best practices
