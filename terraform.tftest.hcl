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
