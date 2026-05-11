// Unit tests for the azure-region module.
// All tests use `command = plan` — no infrastructure is created.

test {
  parallel = true
}

// -------------------------------------------------------------------
// Basic paired-region strategy (default)
// -------------------------------------------------------------------

run "paired_region_eastus" {
  command = plan

  variables {
    primary_region = "eastus"
  }

  assert {
    condition     = output.primary.name == "eastus"
    error_message = "primary.name should be eastus"
  }

  assert {
    condition     = output.primary.short == "eus"
    error_message = "primary.short should be eus"
  }

  assert {
    condition     = output.primary.display_name == "East US"
    error_message = "primary.display_name should be East US"
  }

  assert {
    condition     = output.secondary.name == "westus"
    error_message = "secondary.name should be westus (paired region)"
  }

  assert {
    condition     = output.secondary.short == "wus"
    error_message = "secondary.short should be wus"
  }

  assert {
    condition     = output.strategy == "paired-region"
    error_message = "strategy should be paired-region"
  }

  assert {
    condition     = output.is_allowed == true
    error_message = "is_allowed should be true when no allow-list is set"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "eastus and westus are both United States"
  }
}

// -------------------------------------------------------------------
// Display-name input normalization
// -------------------------------------------------------------------

run "display_name_input" {
  command = plan

  variables {
    primary_region = "East US"
  }

  assert {
    condition     = output.primary.name == "eastus"
    error_message = "primary.name should normalize to eastus"
  }

  assert {
    condition     = output.primary.short == "eus"
    error_message = "primary.short should be eus"
  }

  assert {
    condition     = output.secondary.name == "westus"
    error_message = "secondary should still resolve to westus"
  }
}

// -------------------------------------------------------------------
// Cross-geography pairing (Brazil South → South Central US)
// -------------------------------------------------------------------

run "cross_geography_pair" {
  command = plan

  variables {
    primary_region = "brazilsouth"
  }

  assert {
    condition     = output.secondary.name == "southcentralus"
    error_message = "brazilsouth should pair with southcentralus"
  }

  assert {
    condition     = output.primary.geography == "Brazil"
    error_message = "primary geography should be Brazil"
  }

  assert {
    condition     = output.secondary.geography == "United States"
    error_message = "secondary geography should be United States"
  }

  assert {
    condition     = output.is_cross_geography == true
    error_message = "Brazil and United States are different geographies"
  }

  assert {
    condition     = output.is_cross_zone == false
    error_message = "Both are in Americas compliance zone"
  }
}

// -------------------------------------------------------------------
// Custom strategy
// -------------------------------------------------------------------

run "custom_strategy" {
  command = plan

  variables {
    primary_region   = "eastus"
    secondary_region = "North Europe"
    strategy         = "custom"
  }

  assert {
    condition     = output.primary.name == "eastus"
    error_message = "primary.name should be eastus"
  }

  assert {
    condition     = output.secondary.name == "northeurope"
    error_message = "secondary.name should be northeurope"
  }

  assert {
    condition     = output.secondary.short == "neu"
    error_message = "secondary.short should be neu"
  }

  assert {
    condition     = output.paired_region == "westus"
    error_message = "paired_region should still report westus regardless of strategy"
  }

  assert {
    condition     = output.is_cross_geography == true
    error_message = "United States and Europe are different geographies"
  }

  assert {
    condition     = output.is_cross_zone == true
    error_message = "Americas and EMEA are different compliance zones"
  }
}

// -------------------------------------------------------------------
// Allowed regions — primary allowed
// -------------------------------------------------------------------

run "allowed_regions_primary_allowed" {
  command = plan

  variables {
    primary_region  = "eastus"
    allowed_regions = ["eastus", "westus", "centralus"]
  }

  assert {
    condition     = output.is_allowed == true
    error_message = "eastus should be in allowed list"
  }

  assert {
    condition     = output.is_secondary_allowed == true
    error_message = "westus (paired) should be in allowed list"
  }
}

// -------------------------------------------------------------------
// Allowed regions — primary NOT allowed
// -------------------------------------------------------------------

run "allowed_regions_primary_not_allowed" {
  command = plan

  variables {
    primary_region  = "northeurope"
    allowed_regions = ["eastus", "westus"]
  }

  assert {
    condition     = output.is_allowed == false
    error_message = "northeurope should NOT be in the allowed list"
  }

  assert {
    condition     = output.is_secondary_allowed == false
    error_message = "westeurope (paired) should NOT be in the allowed list"
  }
}

// -------------------------------------------------------------------
// Allowed regions — display-name entries
// -------------------------------------------------------------------

run "allowed_regions_display_names" {
  command = plan

  variables {
    primary_region  = "East US"
    allowed_regions = ["East US", "West US"]
  }

  assert {
    condition     = output.is_allowed == true
    error_message = "is_allowed should normalize display names"
  }
}

// -------------------------------------------------------------------
// Allowed regions enriched output
// -------------------------------------------------------------------

run "allowed_regions_enriched" {
  command = plan

  variables {
    primary_region  = "eastus"
    allowed_regions = ["eastus", "westeurope"]
  }

  assert {
    condition     = output.allowed_regions["eastus"].short == "eus"
    error_message = "enriched eastus short should be eus"
  }

  assert {
    condition     = output.allowed_regions["westeurope"].geography == "Europe"
    error_message = "enriched westeurope geography should be Europe"
  }

  assert {
    condition     = output.allowed_regions["westeurope"].compliance_zone == "EMEA"
    error_message = "enriched westeurope compliance_zone should be EMEA"
  }
}

// -------------------------------------------------------------------
// Custom abbreviation overrides
// -------------------------------------------------------------------

run "custom_abbreviation_override" {
  command = plan

  variables {
    primary_region       = "eastus"
    region_abbreviations = { "eastus" = "east" }
  }

  assert {
    condition     = output.primary.short == "east"
    error_message = "custom abbreviation should override default"
  }

  assert {
    condition     = output.region_abbreviations["eastus"] == "east"
    error_message = "region_abbreviations map should contain the override"
  }
}

// -------------------------------------------------------------------
// UK South → UK West pairing (same geography)
// -------------------------------------------------------------------

run "uksouth_pair" {
  command = plan

  variables {
    primary_region = "uksouth"
  }

  assert {
    condition     = output.primary.short == "uks"
    error_message = "primary.short should be uks"
  }

  assert {
    condition     = output.secondary.name == "ukwest"
    error_message = "secondary should be ukwest"
  }

  assert {
    condition     = output.primary.geography == "United Kingdom"
    error_message = "geography should be United Kingdom"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "compliance_zone should be EMEA"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "uksouth and ukwest are both United Kingdom"
  }
}

// -------------------------------------------------------------------
// Australia East (Asia Pacific zone)
// -------------------------------------------------------------------

run "australia_east" {
  command = plan

  variables {
    primary_region = "australiaeast"
  }

  assert {
    condition     = output.primary.short == "aue"
    error_message = "primary.short should be aue"
  }

  assert {
    condition     = output.primary.compliance_zone == "Asia Pacific"
    error_message = "compliance_zone should be Asia Pacific"
  }

  assert {
    condition     = output.secondary.name == "australiasoutheast"
    error_message = "paired region should be australiasoutheast"
  }
}

// -------------------------------------------------------------------
// Self-pairing region (Poland Central pairs with itself)
// -------------------------------------------------------------------

run "self_pairing_region" {
  command = plan

  variables {
    primary_region = "polandcentral"
  }

  assert {
    condition     = output.primary.name == "polandcentral"
    error_message = "primary.name should be polandcentral"
  }

  assert {
    condition     = output.primary.short == "plc"
    error_message = "primary.short should be plc"
  }

  assert {
    condition     = output.secondary.name == "polandcentral"
    error_message = "polandcentral should pair with itself"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "self-paired region should not be cross-geography"
  }

  assert {
    condition     = output.is_cross_zone == false
    error_message = "self-paired region should not be cross-zone"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "Poland should be in EMEA compliance zone"
  }
}

// -------------------------------------------------------------------
// Cross-zone: Americas ↔ Asia Pacific
// -------------------------------------------------------------------

run "cross_zone_americas_apac" {
  command = plan

  variables {
    primary_region   = "eastus"
    secondary_region = "japaneast"
    strategy         = "custom"
  }

  assert {
    condition     = output.primary.compliance_zone == "Americas"
    error_message = "eastus should be in Americas zone"
  }

  assert {
    condition     = output.secondary.compliance_zone == "Asia Pacific"
    error_message = "japaneast should be in Asia Pacific zone"
  }

  assert {
    condition     = output.is_cross_zone == true
    error_message = "Americas and Asia Pacific are different zones"
  }

  assert {
    condition     = output.is_cross_geography == true
    error_message = "United States and Japan are different geographies"
  }
}

// -------------------------------------------------------------------
// Cross-zone: EMEA ↔ Asia Pacific
// -------------------------------------------------------------------

run "cross_zone_emea_apac" {
  command = plan

  variables {
    primary_region   = "westeurope"
    secondary_region = "australiaeast"
    strategy         = "custom"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "westeurope should be in EMEA zone"
  }

  assert {
    condition     = output.secondary.compliance_zone == "Asia Pacific"
    error_message = "australiaeast should be in Asia Pacific zone"
  }

  assert {
    condition     = output.is_cross_zone == true
    error_message = "EMEA and Asia Pacific are different zones"
  }
}

// -------------------------------------------------------------------
// Non-obvious pairing: eastus2 → centralus
// -------------------------------------------------------------------

run "eastus2_pairs_with_centralus" {
  command = plan

  variables {
    primary_region = "eastus2"
  }

  assert {
    condition     = output.primary.short == "eus2"
    error_message = "primary.short should be eus2"
  }

  assert {
    condition     = output.primary.display_name == "East US 2"
    error_message = "primary.display_name should be East US 2"
  }

  assert {
    condition     = output.secondary.name == "centralus"
    error_message = "eastus2 should pair with centralus"
  }

  assert {
    condition     = output.secondary.short == "cus"
    error_message = "secondary.short should be cus"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "both are United States"
  }
}

// -------------------------------------------------------------------
// Non-obvious pairing: westus3 → eastus
// -------------------------------------------------------------------

run "westus3_pairs_with_eastus" {
  command = plan

  variables {
    primary_region = "westus3"
  }

  assert {
    condition     = output.secondary.name == "eastus"
    error_message = "westus3 should pair with eastus"
  }

  assert {
    condition     = output.primary.short == "wus3"
    error_message = "primary.short should be wus3"
  }

  assert {
    condition     = output.paired_region == "eastus"
    error_message = "paired_region should be eastus"
  }
}

// -------------------------------------------------------------------
// Japan region pairing and Asia Pacific zone
// -------------------------------------------------------------------

run "japan_east_pair" {
  command = plan

  variables {
    primary_region = "japaneast"
  }

  assert {
    condition     = output.primary.short == "jpe"
    error_message = "primary.short should be jpe"
  }

  assert {
    condition     = output.primary.display_name == "Japan East"
    error_message = "primary.display_name should be Japan East"
  }

  assert {
    condition     = output.primary.geography == "Japan"
    error_message = "geography should be Japan"
  }

  assert {
    condition     = output.primary.compliance_zone == "Asia Pacific"
    error_message = "Japan should be in Asia Pacific zone"
  }

  assert {
    condition     = output.secondary.name == "japanwest"
    error_message = "japaneast should pair with japanwest"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "both are Japan"
  }
}

// -------------------------------------------------------------------
// Canada region (Americas zone, non-US geography)
// -------------------------------------------------------------------

run "canada_central" {
  command = plan

  variables {
    primary_region = "canadacentral"
  }

  assert {
    condition     = output.primary.short == "cac"
    error_message = "primary.short should be cac"
  }

  assert {
    condition     = output.primary.geography == "Canada"
    error_message = "geography should be Canada"
  }

  assert {
    condition     = output.primary.compliance_zone == "Americas"
    error_message = "Canada should be in Americas zone"
  }

  assert {
    condition     = output.secondary.name == "canadaeast"
    error_message = "canadacentral should pair with canadaeast"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "both are Canada"
  }
}

// -------------------------------------------------------------------
// UAE region (EMEA zone)
// -------------------------------------------------------------------

run "uae_north" {
  command = plan

  variables {
    primary_region = "uaenorth"
  }

  assert {
    condition     = output.primary.short == "uan"
    error_message = "primary.short should be uan"
  }

  assert {
    condition     = output.primary.geography == "UAE"
    error_message = "geography should be UAE"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "UAE should be in EMEA zone"
  }

  assert {
    condition     = output.secondary.name == "uaecentral"
    error_message = "uaenorth should pair with uaecentral"
  }
}

// -------------------------------------------------------------------
// South Africa (EMEA zone)
// -------------------------------------------------------------------

run "south_africa_north" {
  command = plan

  variables {
    primary_region = "southafricanorth"
  }

  assert {
    condition     = output.primary.short == "san"
    error_message = "primary.short should be san"
  }

  assert {
    condition     = output.primary.geography == "South Africa"
    error_message = "geography should be South Africa"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "South Africa should be in EMEA zone"
  }

  assert {
    condition     = output.secondary.name == "southafricawest"
    error_message = "southafricanorth should pair with southafricawest"
  }
}

// -------------------------------------------------------------------
// India region (Asia Pacific zone)
// -------------------------------------------------------------------

run "central_india" {
  command = plan

  variables {
    primary_region = "centralindia"
  }

  assert {
    condition     = output.primary.short == "cin"
    error_message = "primary.short should be cin"
  }

  assert {
    condition     = output.primary.geography == "India"
    error_message = "geography should be India"
  }

  assert {
    condition     = output.primary.compliance_zone == "Asia Pacific"
    error_message = "India should be in Asia Pacific zone"
  }

  assert {
    condition     = output.secondary.name == "southindia"
    error_message = "centralindia should pair with southindia"
  }
}

// -------------------------------------------------------------------
// North Europe ↔ West Europe pairing (Europe geography)
// -------------------------------------------------------------------

run "north_europe_pair" {
  command = plan

  variables {
    primary_region = "northeurope"
  }

  assert {
    condition     = output.primary.short == "neu"
    error_message = "primary.short should be neu"
  }

  assert {
    condition     = output.primary.geography == "Europe"
    error_message = "geography should be Europe"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "Europe should be in EMEA zone"
  }

  assert {
    condition     = output.secondary.name == "westeurope"
    error_message = "northeurope should pair with westeurope"
  }

  assert {
    condition     = output.secondary.display_name == "West Europe"
    error_message = "secondary display_name should be West Europe"
  }
}

// -------------------------------------------------------------------
// Display-name normalization for secondary_region (custom strategy)
// -------------------------------------------------------------------

run "custom_strategy_display_name_secondary" {
  command = plan

  variables {
    primary_region   = "eastus"
    secondary_region = "West Europe"
    strategy         = "custom"
  }

  assert {
    condition     = output.secondary.name == "westeurope"
    error_message = "secondary should normalize 'West Europe' to westeurope"
  }

  assert {
    condition     = output.secondary.short == "weu"
    error_message = "secondary.short should be weu"
  }

  assert {
    condition     = output.secondary.display_name == "West Europe"
    error_message = "secondary.display_name should be West Europe"
  }
}

// -------------------------------------------------------------------
// Abbreviation override using display-name key
// -------------------------------------------------------------------

run "abbreviation_override_display_name_key" {
  command = plan

  variables {
    primary_region       = "eastus"
    region_abbreviations = { "East US" = "e1" }
  }

  assert {
    condition     = output.primary.short == "e1"
    error_message = "override with display-name key should apply to canonical lookup"
  }
}

// -------------------------------------------------------------------
// Multiple abbreviation overrides at once
// -------------------------------------------------------------------

run "multiple_abbreviation_overrides" {
  command = plan

  variables {
    primary_region = "westeurope"
    region_abbreviations = {
      "westeurope"  = "we"
      "northeurope" = "ne"
    }
  }

  assert {
    condition     = output.primary.short == "we"
    error_message = "primary abbreviation should use override"
  }

  assert {
    condition     = output.secondary.short == "ne"
    error_message = "secondary (paired northeurope → westeurope means secondary is northeurope? No, westeurope pairs with northeurope) abbreviation should use override"
  }

  assert {
    condition     = output.region_abbreviations["westeurope"] == "we"
    error_message = "region_abbreviations should contain westeurope override"
  }

  assert {
    condition     = output.region_abbreviations["northeurope"] == "ne"
    error_message = "region_abbreviations should contain northeurope override"
  }
}

// -------------------------------------------------------------------
// Allowed regions — secondary allowed but primary NOT
// -------------------------------------------------------------------

run "allowed_secondary_but_not_primary" {
  command = plan

  variables {
    primary_region  = "northeurope"
    allowed_regions = ["westeurope"]
  }

  assert {
    condition     = output.is_allowed == false
    error_message = "northeurope should NOT be allowed"
  }

  assert {
    condition     = output.is_secondary_allowed == true
    error_message = "westeurope (paired secondary) SHOULD be allowed"
  }
}

// -------------------------------------------------------------------
// Allowed regions — mixed canonical and display-name entries
// -------------------------------------------------------------------

run "allowed_regions_mixed_formats" {
  command = plan

  variables {
    primary_region  = "westus2"
    allowed_regions = ["West US 2", "eastus", "North Europe"]
  }

  assert {
    condition     = output.is_allowed == true
    error_message = "westus2 should match 'West US 2' after normalization"
  }
}

// -------------------------------------------------------------------
// Enriched allowed regions — display_name and full metadata
// -------------------------------------------------------------------

run "allowed_regions_enriched_full_metadata" {
  command = plan

  variables {
    primary_region  = "eastus"
    allowed_regions = ["japaneast", "uksouth"]
  }

  assert {
    condition     = output.allowed_regions["japaneast"].display_name == "Japan East"
    error_message = "enriched japaneast display_name should be Japan East"
  }

  assert {
    condition     = output.allowed_regions["japaneast"].geography == "Japan"
    error_message = "enriched japaneast geography should be Japan"
  }

  assert {
    condition     = output.allowed_regions["japaneast"].compliance_zone == "Asia Pacific"
    error_message = "enriched japaneast compliance_zone should be Asia Pacific"
  }

  assert {
    condition     = output.allowed_regions["uksouth"].short == "uks"
    error_message = "enriched uksouth short should be uks"
  }

  assert {
    condition     = output.allowed_regions["uksouth"].display_name == "UK South"
    error_message = "enriched uksouth display_name should be UK South"
  }

  assert {
    condition     = output.allowed_regions["uksouth"].compliance_zone == "EMEA"
    error_message = "enriched uksouth compliance_zone should be EMEA"
  }
}

// -------------------------------------------------------------------
// Default region_abbreviations output contains built-in entries
// -------------------------------------------------------------------

run "default_abbreviations_output" {
  command = plan

  variables {
    primary_region = "eastus"
  }

  assert {
    condition     = output.region_abbreviations["eastus"] == "eus"
    error_message = "default abbreviations should contain eastus = eus"
  }

  assert {
    condition     = output.region_abbreviations["westeurope"] == "weu"
    error_message = "default abbreviations should contain westeurope = weu"
  }

  assert {
    condition     = output.region_abbreviations["japaneast"] == "jpe"
    error_message = "default abbreviations should contain japaneast = jpe"
  }

  assert {
    condition     = output.region_abbreviations["southafricanorth"] == "san"
    error_message = "default abbreviations should contain southafricanorth = san"
  }
}

// -------------------------------------------------------------------
// Symmetric pairing: if A pairs with B, B pairs with A
// -------------------------------------------------------------------

run "symmetric_pair_korea" {
  command = plan

  variables {
    primary_region = "koreasouth"
  }

  assert {
    condition     = output.secondary.name == "koreacentral"
    error_message = "koreasouth should pair with koreacentral"
  }

  assert {
    condition     = output.primary.geography == "Korea"
    error_message = "geography should be Korea"
  }
}

// -------------------------------------------------------------------
// France Central ↔ France South pairing (EMEA)
// -------------------------------------------------------------------

run "france_central_pair" {
  command = plan

  variables {
    primary_region = "francecentral"
  }

  assert {
    condition     = output.primary.short == "frc"
    error_message = "primary.short should be frc"
  }

  assert {
    condition     = output.secondary.name == "francesouth"
    error_message = "francecentral should pair with francesouth"
  }

  assert {
    condition     = output.primary.geography == "France"
    error_message = "geography should be France"
  }

  assert {
    condition     = output.primary.compliance_zone == "EMEA"
    error_message = "France should be in EMEA zone"
  }
}

// -------------------------------------------------------------------
// Southeast Asia ↔ East Asia pairing
// -------------------------------------------------------------------

run "southeast_asia_pair" {
  command = plan

  variables {
    primary_region = "southeastasia"
  }

  assert {
    condition     = output.primary.short == "sea"
    error_message = "primary.short should be sea"
  }

  assert {
    condition     = output.primary.display_name == "Southeast Asia"
    error_message = "display_name should be Southeast Asia"
  }

  assert {
    condition     = output.secondary.name == "eastasia"
    error_message = "southeastasia should pair with eastasia"
  }

  assert {
    condition     = output.primary.geography == "Asia Pacific"
    error_message = "geography should be Asia Pacific"
  }

  assert {
    condition     = output.primary.compliance_zone == "Asia Pacific"
    error_message = "compliance_zone should be Asia Pacific"
  }
}

// -------------------------------------------------------------------
// Custom strategy — same geography, same zone
// -------------------------------------------------------------------

run "custom_strategy_same_zone" {
  command = plan

  variables {
    primary_region   = "eastus"
    secondary_region = "westus2"
    strategy         = "custom"
  }

  assert {
    condition     = output.secondary.name == "westus2"
    error_message = "secondary should be westus2"
  }

  assert {
    condition     = output.is_cross_geography == false
    error_message = "both are United States"
  }

  assert {
    condition     = output.is_cross_zone == false
    error_message = "both are Americas"
  }

  assert {
    condition     = output.paired_region == "westus"
    error_message = "paired_region should still be westus even with custom secondary"
  }
}

// -------------------------------------------------------------------
// Germany West Central — multi-word region
// -------------------------------------------------------------------

run "germany_west_central" {
  command = plan

  variables {
    primary_region = "Germany West Central"
  }

  assert {
    condition     = output.primary.name == "germanywestcentral"
    error_message = "should normalize to germanywestcentral"
  }

  assert {
    condition     = output.primary.short == "gwc"
    error_message = "primary.short should be gwc"
  }

  assert {
    condition     = output.primary.display_name == "Germany West Central"
    error_message = "display_name should be Germany West Central"
  }

  assert {
    condition     = output.secondary.name == "germanynorth"
    error_message = "germanywestcentral should pair with germanynorth"
  }

  assert {
    condition     = output.primary.geography == "Germany"
    error_message = "geography should be Germany"
  }
}

// -------------------------------------------------------------------
// Empty allowed_regions means all allowed (explicit)
// -------------------------------------------------------------------

run "empty_allowed_regions_all_allowed" {
  command = plan

  variables {
    primary_region  = "southafricanorth"
    allowed_regions = []
  }

  assert {
    condition     = output.is_allowed == true
    error_message = "is_allowed should be true with empty allowed list"
  }

  assert {
    condition     = output.is_secondary_allowed == true
    error_message = "is_secondary_allowed should be true with empty allowed list"
  }
}

// -------------------------------------------------------------------
// Bidirectional pair: Switzerland North ↔ Switzerland West
// -------------------------------------------------------------------

run "switzerland_bidirectional_pair" {
  command = plan

  variables {
    primary_region = "switzerlandwest"
  }

  assert {
    condition     = output.secondary.name == "switzerlandnorth"
    error_message = "switzerlandwest should pair with switzerlandnorth"
  }

  assert {
    condition     = output.primary.geography == "Switzerland"
    error_message = "geography should be Switzerland"
  }

  assert {
    condition     = output.primary.short == "sww"
    error_message = "primary.short should be sww"
  }

  assert {
    condition     = output.secondary.short == "swn"
    error_message = "secondary.short should be swn"
  }
}

// -------------------------------------------------------------------
// Cross-geography within same zone: Canada ↔ US (custom)
// -------------------------------------------------------------------

run "cross_geography_same_zone_americas" {
  command = plan

  variables {
    primary_region   = "canadacentral"
    secondary_region = "eastus"
    strategy         = "custom"
  }

  assert {
    condition     = output.primary.geography == "Canada"
    error_message = "primary geography should be Canada"
  }

  assert {
    condition     = output.secondary.geography == "United States"
    error_message = "secondary geography should be United States"
  }

  assert {
    condition     = output.is_cross_geography == true
    error_message = "Canada and United States are different geographies"
  }

  assert {
    condition     = output.is_cross_zone == false
    error_message = "both are in Americas compliance zone"
  }
}
