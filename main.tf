# #######################################################
# Azure Region Helper Module — Core Logic
#
# Source:
# https://github.com/Build5Nines/terraform-azure-region-map
#
# Author: Chris Pietschmann (https://pietschsoft.com)
# Copyright (c) 2026 Build5Nine LLC (https://build5nines.com)
# #######################################################

locals {
  # -------------------------------------------------------------------
  # Reference data
  # -------------------------------------------------------------------
  _region_abbr          = jsondecode(file("${path.module}/data/region_abbr.json"))
  _region_pair          = jsondecode(file("${path.module}/data/region_pair.json"))
  _region_display_names = jsondecode(file("${path.module}/data/region_display_names.json"))
  _region_geography     = jsondecode(file("${path.module}/data/region_geography.json"))

  # Merge user-supplied abbreviation overrides (normalize keys so both
  # "East US" and "eastus" forms are accepted).
  region_abbr = merge(
    local._region_abbr,
    var.region_abbreviations,
    { for k, v in var.region_abbreviations : lower(replace(k, " ", "")) => v }
  )

  # -------------------------------------------------------------------
  # Compliance-zone grouping derived from geography
  # -------------------------------------------------------------------
  _compliance_zones = {
    "United States"  = "Americas"
    "Canada"         = "Americas"
    "Brazil"         = "Americas"
    "Mexico"         = "Americas"
    "Chile"          = "Americas"
    "Europe"         = "EMEA"
    "United Kingdom" = "EMEA"
    "France"         = "EMEA"
    "Germany"        = "EMEA"
    "Switzerland"    = "EMEA"
    "Norway"         = "EMEA"
    "Sweden"         = "EMEA"
    "Poland"         = "EMEA"
    "Austria"        = "EMEA"
    "Belgium"        = "EMEA"
    "Spain"          = "EMEA"
    "Italy"          = "EMEA"
    "UAE"            = "EMEA"
    "Qatar"          = "EMEA"
    "Israel"         = "EMEA"
    "South Africa"   = "EMEA"
    "Asia Pacific"   = "Asia Pacific"
    "Japan"          = "Asia Pacific"
    "Korea"          = "Asia Pacific"
    "Australia"      = "Asia Pacific"
    "New Zealand"    = "Asia Pacific"
    "India"          = "Asia Pacific"
    "Indonesia"      = "Asia Pacific"
    "Malaysia"       = "Asia Pacific"
  }

  # -------------------------------------------------------------------
  # Primary region
  # -------------------------------------------------------------------
  primary_canonical    = lower(replace(var.primary_region, " ", ""))
  primary_abbr         = try(local.region_abbr[local.primary_canonical], local.primary_canonical)
  primary_display_name = try(local._region_display_names[local.primary_canonical], local.primary_canonical)
  primary_geography    = try(local._region_geography[local.primary_canonical], "unknown")
  primary_zone         = try(local._compliance_zones[local.primary_geography], "unknown")

  # -------------------------------------------------------------------
  # Secondary region (strategy-dependent)
  # -------------------------------------------------------------------
  paired_region_canonical = try(local._region_pair[local.primary_canonical], "")

  secondary_canonical = (
    var.strategy == "custom"
    ? lower(replace(var.secondary_region, " ", ""))
    : local.paired_region_canonical
  )

  secondary_abbr         = try(local.region_abbr[local.secondary_canonical], local.secondary_canonical)
  secondary_display_name = try(local._region_display_names[local.secondary_canonical], local.secondary_canonical)
  secondary_geography    = try(local._region_geography[local.secondary_canonical], "unknown")
  secondary_zone         = try(local._compliance_zones[local.secondary_geography], "unknown")

  # -------------------------------------------------------------------
  # Policy / allowed-regions evaluation
  # -------------------------------------------------------------------
  allowed_canonical    = [for r in var.allowed_regions : lower(replace(r, " ", ""))]
  has_allow_list       = length(var.allowed_regions) > 0
  is_allowed           = !local.has_allow_list || contains(local.allowed_canonical, local.primary_canonical)
  is_secondary_allowed = !local.has_allow_list || contains(local.allowed_canonical, local.secondary_canonical)

  # Enriched map of each allowed region with abbreviation & metadata
  allowed_regions_enriched = {
    for r in local.allowed_canonical : r => {
      name            = r
      short           = try(local.region_abbr[r], r)
      display_name    = try(local._region_display_names[r], r)
      geography       = try(local._region_geography[r], "unknown")
      compliance_zone = try(local._compliance_zones[try(local._region_geography[r], "unknown")], "unknown")
    }
  }

  # -------------------------------------------------------------------
  # Cross-geography / cross-zone flags (useful for DR decisions)
  # -------------------------------------------------------------------
  is_cross_geography = local.primary_geography != local.secondary_geography
  is_cross_zone      = local.primary_zone != local.secondary_zone
}
