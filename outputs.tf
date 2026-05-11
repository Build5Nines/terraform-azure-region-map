# #######################################################
# Azure Region Helper Module — Outputs
#
# Source:
# https://github.com/Build5Nines/terraform-azure-region-map
#
# Author: Chris Pietschmann (https://pietschsoft.com)
# Copyright (c) 2026 Build5Nine LLC
# #######################################################

# -------------------------------------------------------------------
# Primary region
# -------------------------------------------------------------------

output "primary" {
  description = "Primary region details: canonical name, abbreviation, display name, geography, and compliance zone."
  value = {
    name            = local.primary_canonical
    short           = local.primary_abbr
    display_name    = local.primary_display_name
    geography       = local.primary_geography
    compliance_zone = local.primary_zone
  }
}

# -------------------------------------------------------------------
# Secondary region
# -------------------------------------------------------------------

output "secondary" {
  description = "Secondary region details: canonical name, abbreviation, display name, geography, and compliance zone."
  value = {
    name            = local.secondary_canonical
    short           = local.secondary_abbr
    display_name    = local.secondary_display_name
    geography       = local.secondary_geography
    compliance_zone = local.secondary_zone
  }
}

# -------------------------------------------------------------------
# Strategy & pairing
# -------------------------------------------------------------------

output "strategy" {
  description = "The strategy used for secondary region selection."
  value       = var.strategy
}

output "paired_region" {
  description = "Azure's designated paired region for the primary region, regardless of the selected strategy."
  value       = local.paired_region_canonical
}

# -------------------------------------------------------------------
# Policy compliance
# -------------------------------------------------------------------

output "is_allowed" {
  description = "Whether the primary region is in the allowed_regions list (true when no allow-list is set)."
  value       = local.is_allowed
}

output "is_secondary_allowed" {
  description = "Whether the secondary region is in the allowed_regions list (true when no allow-list is set)."
  value       = local.is_secondary_allowed
}

output "allowed_regions" {
  description = "Enriched map of each allowed region with abbreviation, display name, geography, and compliance zone."
  value       = local.allowed_regions_enriched
}

# -------------------------------------------------------------------
# DR / geography flags
# -------------------------------------------------------------------

output "is_cross_geography" {
  description = "Whether primary and secondary regions reside in different geographies."
  value       = local.is_cross_geography
}

output "is_cross_zone" {
  description = "Whether primary and secondary regions reside in different compliance zones (Americas / EMEA / Asia Pacific)."
  value       = local.is_cross_zone
}

# -------------------------------------------------------------------
# Reference data (for consumers that need the full maps)
# -------------------------------------------------------------------

output "region_abbreviations" {
  description = "Complete region → abbreviation map (defaults merged with any user overrides)."
  value       = local.region_abbr
}
