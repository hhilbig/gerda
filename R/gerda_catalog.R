#' Internal catalog of downloadable GERDA datasets
#'
#' Single source of truth for every dataset that \code{\link{load_gerda_web}}
#' can download. Both \code{load_gerda_web()} (which derives the download URLs
#' from \code{path}) and \code{\link{gerda_data_list}} (which surfaces the
#' metadata to users) read from here, so the two can never drift apart.
#'
#' Columns:
#' \describe{
#'   \item{data_name}{Dataset key passed to \code{load_gerda_web()}.}
#'   \item{description}{One-line human-readable description.}
#'   \item{path}{Repository subpath under \code{data/}, used to build the
#'     CSV/RDS download URLs.}
#'   \item{election_type}{One of \code{municipal}, \code{state}, \code{federal},
#'     \code{county-kreistag}, \code{european}, \code{mayoral}, \code{landrat},
#'     \code{crosswalk}, \code{covariate}.}
#'   \item{geographic_level}{\code{municipality}, \code{county},
#'     \code{wahlkreis} (Bundestag constituency), or \code{person}.}
#'   \item{year_start, year_end}{Election year range (integer), or \code{NA}
#'     where the description does not state an explicit range (e.g. crosswalks,
#'     covariates, and harmonized files without a stated span).}
#'   \item{boundary}{Harmonization target: \code{unharmonized}, \code{raw},
#'     \code{harmonized} (unspecified target), \code{current}, \code{2021},
#'     \code{2023}, \code{2025}, or \code{NA} (crosswalks / covariates).}
#'   \item{formats}{Available download formats, \code{"csv,rds"} or \code{"rds"}
#'     for the RDS-only crosswalks.}
#'   \item{candidate_info}{\code{TRUE} if the dataset includes person-level
#'     candidate / office-holder identities.}
#' }
#'
#' @return A data.frame with one row per dataset.
#' @keywords internal
#' @noRd
gerda_catalog <- function() {
    ds <- function(data_name, description, path, election_type,
                   geographic_level, year_start = NA, year_end = NA,
                   boundary = NA_character_, formats = "csv,rds",
                   candidate_info = FALSE) {
        data.frame(
            data_name        = data_name,
            description      = description,
            path             = path,
            election_type    = election_type,
            geographic_level = geographic_level,
            year_start       = as.integer(year_start),
            year_end         = as.integer(year_end),
            boundary         = boundary,
            formats          = formats,
            candidate_info   = candidate_info,
            stringsAsFactors = FALSE
        )
    }

    rbind(
        # Local (municipal) elections
        ds("municipal_unharm",
           "Local elections at the municipal level (1984-2026, unharmonized; includes council seat counts (seats_*) where the state source reports them).",
           "municipal_elections/final/municipal_unharm",
           "municipal", "municipality", 1984, 2026, "unharmonized"),
        ds("municipal_harm",
           "Local elections at the municipal level (1990-2026, harmonized).",
           "municipal_elections/final/municipal_harm",
           "municipal", "municipality", 1990, 2026, "harmonized"),
        ds("municipal_harm_25",
           "Local elections at the municipal level (1990-2026, harmonized to 2025 boundaries).",
           "municipal_elections/final/municipal_harm_25",
           "municipal", "municipality", 1990, 2026, "2025"),

        # State (Landtag) elections
        ds("state_unharm",
           "State elections at the municipal level (2006-2019, unharmonized).",
           "state_elections/final/state_unharm",
           "state", "municipality", 2006, 2019, "unharmonized"),
        ds("state_harm",
           "State elections at the municipal level (2006-2019, harmonized).",
           "state_elections/final/state_harm",
           "state", "municipality", 2006, 2019, "harmonized"),
        ds("state_harm_21",
           "State elections at the municipal level, harmonized to 2021 boundaries.",
           "state_elections/final/state_harm_21",
           "state", "municipality", NA, NA, "2021"),
        ds("state_harm_23",
           "State elections at the municipal level, harmonized to 2023 boundaries.",
           "state_elections/final/state_harm_23",
           "state", "municipality", NA, NA, "2023"),
        ds("state_harm_25",
           "State elections at the municipal level, harmonized to 2025 boundaries.",
           "state_elections/final/state_harm_25",
           "state", "municipality", NA, NA, "2025"),
        ds("ltw_wkr_unharm",
           "State (Landtag) elections at the Wahlkreis (constituency) level (1990-2026, unharmonized).",
           "state_elections/final/ltw_wkr_unharm",
           "state", "wahlkreis", 1990, 2026, "unharmonized"),
        ds("ltw_wkr_unharm_long",
           "State (Landtag) elections at the Wahlkreis level (1990-2026), long format with vote counts.",
           "state_elections/final/ltw_wkr_unharm_long",
           "state", "wahlkreis", 1990, 2026, "unharmonized"),

        # Federal elections
        ds("federal_muni_raw",
           "Federal elections at the municipal level (1980-2025, raw data).",
           "federal_elections/municipality_level/final/federal_muni_raw",
           "federal", "municipality", 1980, 2025, "raw"),
        ds("federal_muni_unharm",
           "Federal elections at the municipal level (1980-2025, unharmonized).",
           "federal_elections/municipality_level/final/federal_muni_unharm",
           "federal", "municipality", 1980, 2025, "unharmonized"),
        ds("federal_muni_harm_21",
           "Federal elections at the municipal level (1990-2025, harmonized to 2021 boundaries).",
           "federal_elections/municipality_level/final/federal_muni_harm_21",
           "federal", "municipality", 1990, 2025, "2021"),
        ds("federal_muni_harm_25",
           "Federal elections at the municipal level (1990-2025, harmonized to 2025 boundaries).",
           "federal_elections/municipality_level/final/federal_muni_harm_25",
           "federal", "municipality", 1990, 2025, "2025"),
        ds("federal_cty_unharm",
           "Federal elections at the county level (1953-2021, unharmonized).",
           "federal_elections/county_level/final/federal_cty_unharm",
           "federal", "county", 1953, 2021, "unharmonized"),
        ds("federal_cty_harm",
           "Federal elections at the county level (1990-2021, harmonized).",
           "federal_elections/county_level/final/federal_cty_harm",
           "federal", "county", 1990, 2021, "harmonized"),
        ds("federal_wkr_unharm",
           "Federal elections at the Wahlkreis (constituency) level (2002-2025, unharmonized).",
           "federal_elections/wahlkreis_level/final/federal_wkr_unharm",
           "federal", "wahlkreis", 2002, 2025, "unharmonized"),
        ds("federal_wkr_unharm_long",
           "Federal elections at the Wahlkreis level (2002-2025), long format with vote counts.",
           "federal_elections/wahlkreis_level/final/federal_wkr_unharm_long",
           "federal", "wahlkreis", 2002, 2025, "unharmonized"),
        ds("federal_wkr_2021_on_2025",
           "Federal 2021 result recomputed onto the 2025 Wahlkreis boundaries (official recomputation).",
           "federal_elections/wahlkreis_level/final/federal_wkr_2021_on_2025",
           "federal", "wahlkreis", 2021, 2021, "2025"),

        # County (Kreistag) elections
        ds("county_elec_unharm",
           "County (Kreistag) elections at the municipal level, unharmonized.",
           "county_elections/final/county_elec_unharm",
           "county-kreistag", "municipality", NA, NA, "unharmonized"),
        ds("county_elec_harm_21_cty",
           "County (Kreistag) elections aggregated to county level, harmonized to 2021 boundaries.",
           "county_elections/final/county_elec_harm_21_cty",
           "county-kreistag", "county", NA, NA, "2021"),
        ds("county_elec_harm_21_muni",
           "County (Kreistag) elections at the municipal level, harmonized to 2021 boundaries.",
           "county_elections/final/county_elec_harm_21_muni",
           "county-kreistag", "municipality", NA, NA, "2021"),
        ds("county_council_seats",
           "County council (Kreistag) seat composition, yearly panel on fixed current county boundaries (2008-2025).",
           "county_elections/final/county_council_seats",
           "county-kreistag", "county", 2008, 2025, "current"),

        # European Parliament elections
        ds("european_muni_unharm",
           "European Parliament elections at the municipal level, unharmonized.",
           "european_elections/final/european_muni_unharm",
           "european", "municipality", NA, NA, "unharmonized"),
        ds("european_muni_harm",
           "European Parliament elections at the municipal level, harmonized.",
           "european_elections/final/european_muni_harm",
           "european", "municipality", NA, NA, "harmonized"),

        # Mayoral elections
        ds("mayoral_unharm",
           "Mayoral election results at the municipal level, unharmonized.",
           "mayoral_elections/final/mayoral_unharm",
           "mayoral", "municipality", NA, NA, "unharmonized"),
        ds("mayoral_harm",
           "Mayoral election results at the municipal level, harmonized.",
           "mayoral_elections/final/mayoral_harm",
           "mayoral", "municipality", NA, NA, "harmonized"),
        ds("mayoral_candidates",
           "Mayoral candidates (person-level).",
           "mayoral_elections/final/mayoral_candidates",
           "mayoral", "person", NA, NA, NA_character_, "csv,rds", TRUE),
        ds("mayor_panel",
           "Mayor panel (person-level, one row per mayor-term).",
           "mayoral_elections/final/mayor_panel",
           "mayoral", "person", NA, NA, "unharmonized", "csv,rds", TRUE),
        ds("mayor_panel_harm",
           "Mayor panel (person-level, harmonized to current boundaries).",
           "mayoral_elections/final/mayor_panel_harm",
           "mayoral", "person", NA, NA, "current", "csv,rds", TRUE),
        ds("mayor_panel_annual",
           "Mayor panel at annual frequency (one row per municipality-year).",
           "mayoral_elections/final/mayor_panel_annual",
           "mayoral", "municipality", NA, NA, "unharmonized", "csv,rds", TRUE),
        ds("mayor_panel_annual_harm",
           "Mayor panel at annual frequency, harmonized to current boundaries.",
           "mayoral_elections/final/mayor_panel_annual_harm",
           "mayoral", "municipality", NA, NA, "current", "csv,rds", TRUE),

        # Landrat (county executive) elections
        ds("landrat_unharm",
           "Landrat (county executive) elections at the county level (1945-2026, unharmonized).",
           "landrat_elections/final/landrat_unharm",
           "landrat", "county", 1945, 2026, "unharmonized"),
        ds("landrat_candidates",
           "Landrat candidates (person-level, includes Stichwahl and candidate attributes).",
           "landrat_elections/final/landrat_candidates",
           "landrat", "person", 1945, 2026, NA_character_, "csv,rds", TRUE),

        # Crosswalks
        ds("ags_crosswalks",
           "Crosswalks for municipalities (1990-2025).",
           "crosswalks/final/ags_crosswalks",
           "crosswalk", "municipality"),
        ds("cty_crosswalks",
           "Crosswalks for counties (1990-2025).",
           "crosswalks/final/cty_crosswalks",
           "crosswalk", "county"),
        ds("wkr_2021_to_2025_crosswalk",
           "Bundestag Wahlkreis crosswalk: 2021 to 2025 (unchanged / redrawn / new).",
           "federal_elections/wahlkreis_level/final/wkr_2021_to_2025_crosswalk",
           "crosswalk", "wahlkreis"),
        ds("ags_1990_to_2023_crosswalk",
           "Municipality crosswalk: 1990 boundaries to 2023 boundaries.",
           "crosswalks/final/ags_1990_to_2023_crosswalk",
           "crosswalk", "municipality"),
        ds("ags_1990_to_2025_crosswalk",
           "Municipality crosswalk: 1990 boundaries to 2025 boundaries.",
           "crosswalks/final/ags_1990_to_2025_crosswalk",
           "crosswalk", "municipality"),
        ds("crosswalk_ags_2021_to_2023",
           "Municipality crosswalk: AGS 2021 to AGS 2023 (targeted).",
           "crosswalks/final/crosswalk_ags_2021_to_2023",
           "crosswalk", "municipality"),
        ds("crosswalk_ags_2021_2022_to_2023",
           "Municipality crosswalk: AGS 2021 and 2022 to AGS 2023 (targeted).",
           "crosswalks/final/crosswalk_ags_2021_2022_to_2023",
           "crosswalk", "municipality"),
        ds("crosswalk_ags_2023_to_2025",
           "Municipality crosswalk: AGS 2023 to AGS 2025 (targeted; RDS only).",
           "crosswalks/final/crosswalk_ags_2023_to_2025",
           "crosswalk", "municipality", NA, NA, NA_character_, "rds"),
        ds("crosswalk_ags_2023_24_to_2025",
           "Municipality crosswalk: AGS 2023 and 2024 to AGS 2025 (targeted; RDS only).",
           "crosswalks/final/crosswalk_ags_2023_24_to_2025",
           "crosswalk", "municipality", NA, NA, NA_character_, "rds"),
        ds("crosswalk_ags_2024_to_2025",
           "Municipality crosswalk: AGS 2024 to AGS 2025 (targeted; RDS only).",
           "crosswalks/final/crosswalk_ags_2024_to_2025",
           "crosswalk", "municipality", NA, NA, NA_character_, "rds"),

        # Crosswalk covariates
        ds("ags_area_pop_emp",
           "Crosswalk covariates (area, population, employment) for municipalities (1990-2025).",
           "covars_municipality/final/ags_area_pop_emp",
           "covariate", "municipality"),
        ds("ags_area_pop_emp_2023",
           "Crosswalk covariates (area, population, employment) for municipalities, harmonized to 2023 boundaries.",
           "covars_municipality/final/ags_area_pop_emp_2023",
           "covariate", "municipality", NA, NA, "2023"),
        ds("cty_area_pop_emp",
           "Crosswalk covariates (area, population, employment) for counties (1990-2025).",
           "covars_county/final/cty_area_pop_emp",
           "covariate", "county")
    )
}
