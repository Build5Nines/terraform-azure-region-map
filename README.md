# Azure Region Helper Terraform Module from Build5Nines

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An opinionated region and abbreviation helper for enterprise multi-region Terraform deployments.

**Problem it solves:** Multi-region Terraform gets messy fast — primary/secondary regions, short codes, paired regions, allowed regions, data-residency zones, and naming abbreviations. This module wraps all of that into a single, enterprise-focused interface so you can stop hand-coding region lookups and focus on infrastructure.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Input Variables](#input-variables)
- [Outputs](#outputs)
- [Key Concepts](#key-concepts)
  - [Region Input Normalization](#region-input-normalization)
  - [Secondary Region Strategy](#secondary-region-strategy)
  - [Policy Compliance (Allowed Regions)](#policy-compliance-allowed-regions)
  - [Geography and Compliance Zones](#geography-and-compliance-zones)
  - [Region Abbreviation Overrides](#region-abbreviation-overrides)
- [Enterprise Use Cases](#enterprise-use-cases)
  - [Landing Zone Policy Gating](#landing-zone-policy-gating)
  - [Disaster Recovery Planning](#disaster-recovery-planning)
  - [Multi-Region Resource Naming](#multi-region-resource-naming)
  - [Custom Secondary Region](#custom-secondary-region)
  - [Data Residency Compliance](#data-residency-compliance)
- [Data Sources](#data-sources)
- [Running Tests](#running-tests)
- [How It Differs from AVM Azure Regions Data](#how-it-differs-from-avm-azure-regions-data)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automatic paired-region resolution** — Looks up Azure's designated regional pair for any primary region.
- **Flexible secondary region strategy** — Use the Azure pair or specify a custom secondary region.
- **Built-in abbreviations** — Short codes for 60+ Azure regions (e.g. `eastus` → `eus`), with override support.
- **Display name resolution** — Maps canonical names to human-readable display names (e.g. `eastus` → `East US`).
- **Policy compliance gating** — Define an allow-list of approved regions and check deployments against it.
- **Geography & compliance zone metadata** — Know each region's geography (e.g. `United States`, `Europe`) and compliance zone (`Americas`, `EMEA`, `Asia Pacific`).
- **Cross-geography / cross-zone flags** — Instantly determine if your primary and secondary regions span geographies or compliance zones for DR and data-residency decisions.
- **Input normalization** — Accepts both canonical names (`eastus`) and display names (`East US`).
- **No providers required** — Pure Terraform logic with local JSON data; no API calls, no credentials needed.

## Requirements

| Requirement | Version |
|-------------|---------|
| Terraform   | `>= 1.0` |

No Azure provider configuration is required. This module uses only local JSON data files and Terraform built-in functions.

## Getting Started

### 1. Add the module to your configuration

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"
  version = "~> 1.0.0"   # pin to a version

  primary_region = "eastus"
}
```

### 2. Reference the outputs

```terraform
# Use the abbreviation for naming conventions
resource "azurerm_resource_group" "main" {
  name     = "rg-myapp-${module.regions.primary.short}-prd"
  location = module.regions.primary.name
}

# Use the secondary region for DR
resource "azurerm_resource_group" "dr" {
  name     = "rg-myapp-${module.regions.secondary.short}-prd"
  location = module.regions.secondary.name
}
```

### 3. Inspect all available outputs

```terraform
module.regions.primary
# {
#   name            = "eastus"
#   short           = "eus"
#   display_name    = "East US"
#   geography       = "United States"
#   compliance_zone = "Americas"
# }

module.regions.secondary
# {
#   name            = "westus"
#   short           = "wus"
#   display_name    = "West US"
#   geography       = "United States"
#   compliance_zone = "Americas"
# }

module.regions.is_allowed           # true
module.regions.is_secondary_allowed # true
module.regions.is_cross_geography   # false
module.regions.is_cross_zone        # false
module.regions.paired_region        # "westus"
module.regions.strategy             # "paired-region"
```

## Input Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `primary_region` | `string` | — | **Yes** | The primary Azure region. Accepts canonical names (`eastus`) or display names (`East US`). |
| `secondary_region` | `string` | `""` | No | Explicit secondary Azure region. **Required** when `strategy = "custom"`. Ignored otherwise. |
| `strategy` | `string` | `"paired-region"` | No | Strategy for selecting the secondary region. Must be `"paired-region"` or `"custom"`. |
| `allowed_regions` | `list(string)` | `[]` | No | List of Azure regions approved for deployment (policy compliance). When empty, all regions are considered allowed. Accepts both canonical and display names. |
| `region_abbreviations` | `map(string)` | `{}` | No | Custom region → abbreviation overrides. Keys may be display names (`"East US"`) or canonical names (`"eastus"`). |

## Outputs

### Region Detail Objects

| Name | Type | Description |
|------|------|-------------|
| `primary` | `object` | Primary region details with attributes: `name`, `short`, `display_name`, `geography`, `compliance_zone`. |
| `secondary` | `object` | Secondary region details (same shape as `primary`). |

Each region object contains:

| Attribute | Type | Example | Description |
|-----------|------|---------|-------------|
| `name` | `string` | `"eastus"` | Canonical region name. |
| `short` | `string` | `"eus"` | Short abbreviation for naming conventions. |
| `display_name` | `string` | `"East US"` | Human-readable display name. |
| `geography` | `string` | `"United States"` | Geographic region / country. |
| `compliance_zone` | `string` | `"Americas"` | Compliance zone: `Americas`, `EMEA`, or `Asia Pacific`. |

### Strategy & Pairing

| Name | Type | Description |
|------|------|-------------|
| `strategy` | `string` | The strategy used for secondary region selection (`"paired-region"` or `"custom"`). |
| `paired_region` | `string` | Azure's designated paired region for the primary region, **regardless** of the selected strategy. |

### Policy Compliance

| Name | Type | Description |
|------|------|-------------|
| `is_allowed` | `bool` | Whether the primary region is in the `allowed_regions` list. Always `true` when no allow-list is set. |
| `is_secondary_allowed` | `bool` | Whether the secondary region is in the `allowed_regions` list. Always `true` when no allow-list is set. |
| `allowed_regions` | `map(object)` | Enriched map of each allowed region with `name`, `short`, `display_name`, `geography`, and `compliance_zone`. |

### DR / Geography Flags

| Name | Type | Description |
|------|------|-------------|
| `is_cross_geography` | `bool` | `true` if primary and secondary regions reside in different geographies (e.g. `United States` vs `Europe`). |
| `is_cross_zone` | `bool` | `true` if primary and secondary regions reside in different compliance zones (e.g. `Americas` vs `EMEA`). |

### Reference Data

| Name | Type | Description |
|------|------|-------------|
| `region_abbreviations` | `map(string)` | Complete region → abbreviation map (built-in defaults merged with any user overrides). |

## Key Concepts

### Region Input Normalization

The module normalizes all region inputs by converting to lowercase and removing spaces. This means both of these are equivalent:

```terraform
primary_region = "eastus"
primary_region = "East US"
```

The same normalization applies to `secondary_region` and entries in `allowed_regions`.

### Secondary Region Strategy

The `strategy` variable controls how the secondary region is determined:

| Strategy | Behavior |
|----------|----------|
| `"paired-region"` (default) | Automatically looks up Azure's designated [regional pair](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure#azure-cross-region-replication-pairings-for-all-geographies) for the primary region. |
| `"custom"` | Uses the value you provide in `secondary_region`. |

When using `"paired-region"`, the `paired_region` output and `secondary` output will match. When using `"custom"`, the `paired_region` output still shows Azure's designated pair for reference, while `secondary` reflects your custom choice.

### Policy Compliance (Allowed Regions)

Pass a list of approved regions to `allowed_regions` to enable policy gating:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region  = var.region
  allowed_regions = ["eastus", "westus", "centralus"]
}

# Then check:
# module.regions.is_allowed            → true/false
# module.regions.is_secondary_allowed  → true/false
```

When `allowed_regions` is empty (the default), `is_allowed` and `is_secondary_allowed` are always `true`.

The `allowed_regions` output provides an enriched map with full metadata for each approved region, useful for generating documentation or populating dropdowns:

```terraform
module.regions.allowed_regions["eastus"]
# {
#   name            = "eastus"
#   short           = "eus"
#   display_name    = "East US"
#   geography       = "United States"
#   compliance_zone = "Americas"
# }
```

### Geography and Compliance Zones

Each region is mapped to a **geography** (e.g. `United States`, `United Kingdom`, `Europe`, `Brazil`) and a higher-level **compliance zone**:

| Compliance Zone | Geographies |
|-----------------|-------------|
| **Americas** | United States, Canada, Brazil, Mexico, Chile |
| **EMEA** | Europe, United Kingdom, France, Germany, Switzerland, Norway, Sweden, Poland, Austria, Belgium, Spain, Italy, UAE, Qatar, Israel, South Africa |
| **Asia Pacific** | Asia Pacific, Japan, Korea, Australia, New Zealand, India, Indonesia, Malaysia |

Use `is_cross_geography` and `is_cross_zone` to make data-residency and DR topology decisions:

```terraform
# Brazil South pairs with South Central US — same zone, different geography
module.regions.is_cross_geography  # true
module.regions.is_cross_zone       # false  (both Americas)

# East US + North Europe (custom) — different zone AND geography
module.regions.is_cross_geography  # true
module.regions.is_cross_zone       # true   (Americas ↔ EMEA)
```

### Region Abbreviation Overrides

The module ships with built-in abbreviations for 60+ Azure regions. You can override any of them:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region       = "eastus"
  region_abbreviations = {
    "eastus" = "east"
    "westus" = "west"
  }
}

# module.regions.primary.short  → "east" (overridden)
```

Override keys accept both canonical names (`"eastus"`) and display names (`"East US"`).

## Enterprise Use Cases

### Landing Zone Policy Gating

Enforce that deployments only target approved regions:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region  = var.region
  allowed_regions = var.approved_regions
}

# Gate deployments on policy
resource "null_resource" "policy_check" {
  count = module.regions.is_allowed ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'Region ${var.region} is not in the approved list' && exit 1"
  }
}
```

### Disaster Recovery Planning

Automatically resolve paired regions and assess DR topology:

```terraform
module "dr_regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region = "uksouth"
}

# Outputs:
# module.dr_regions.primary.name         = "uksouth"
# module.dr_regions.secondary.name       = "ukwest"
# module.dr_regions.is_cross_geography   = false   (both United Kingdom)
# module.dr_regions.is_cross_zone        = false   (both EMEA)
# module.dr_regions.primary.compliance_zone = "EMEA"
```

Use the cross-geography flag to warn when DR pairing crosses data-residency boundaries:

```terraform
module "dr_regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region = "brazilsouth"
}

# module.dr_regions.secondary.name     = "southcentralus"
# module.dr_regions.is_cross_geography = true   (Brazil ↔ United States)
# module.dr_regions.is_cross_zone      = false  (both Americas)
```

### Multi-Region Resource Naming

Use abbreviations for consistent, concise resource names across regions:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region = var.location
}

locals {
  primary_rg_name   = "rg-${var.app}-${module.regions.primary.short}-${var.env}"
  secondary_rg_name = "rg-${var.app}-${module.regions.secondary.short}-${var.env}"
}
# Example: rg-myapp-eus-prd / rg-myapp-wus-prd
```

### Custom Secondary Region

Override the Azure pair when your DR strategy targets a specific region:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region   = "eastus"
  secondary_region = "North Europe"
  strategy         = "custom"
}

# module.regions.secondary.name      = "northeurope"
# module.regions.secondary.short     = "neu"
# module.regions.is_cross_zone       = true   (Americas ↔ EMEA)
# module.regions.is_cross_geography  = true   (United States ↔ Europe)
# module.regions.paired_region       = "westus"  (Azure pair still available)
```

### Data Residency Compliance

Use the enriched allowed-regions output to build compliant multi-region deployments:

```terraform
module "regions" {
  source  = "Build5Nines/region-map/azure"

  primary_region  = "westeurope"
  allowed_regions = ["westeurope", "northeurope", "uksouth", "ukwest"]
}

# Filter allowed regions to only those in the EMEA compliance zone
locals {
  emea_regions = {
    for k, v in module.regions.allowed_regions : k => v
    if v.compliance_zone == "EMEA"
  }
}
```

## Data Sources

Region data is stored in static JSON files under `data/`. No API calls or provider credentials are required.

| File | Description |
|------|-------------|
| `region_abbr.json` | Canonical region name → short abbreviation (e.g. `"eastus": "eus"`). |
| `region_pair.json` | Canonical region name → Azure paired region (e.g. `"eastus": "westus"`). |
| `region_display_names.json` | Canonical region name → display name (e.g. `"eastus": "East US"`). |
| `region_geography.json` | Canonical region name → geography / country (e.g. `"eastus": "United States"`). |

> **Note:** The data files cover 60+ Azure regions. If a region is missing, you can submit a PR to add it to the JSON files, or use `region_abbreviations` to supply abbreviation overrides at the module level.

## Running Tests

The module includes comprehensive unit tests using Terraform's native test framework. All tests use `command = plan` — **no infrastructure is created**.

```bash
terraform init
terraform test
```

The test suite covers:
- Paired-region resolution (East US, UK South, Australia East, Brazil South)
- Display-name input normalization
- Cross-geography and cross-zone flag accuracy
- Custom strategy with explicit secondary region
- Allowed-regions policy gating (allowed, not allowed, display-name entries)
- Enriched allowed-regions output metadata
- Custom abbreviation overrides

## How It Differs from AVM Azure Regions Data

| Concern | AVM Regions Data | This Module |
|---------|------------------|-------------|
| Focus | Raw Azure region metadata | Enterprise deployment decisions |
| Paired regions | Data only | Strategy-driven selection |
| Abbreviations | Not included | Built-in with overrides |
| Policy compliance | Not included | `allowed_regions` + `is_allowed` |
| Data residency | Not included | Geography + compliance zones |
| DR helpers | Not included | Cross-geography/zone flags |
| Provider required | Yes (AzureRM) | No — pure Terraform + local JSON |

## Contributing

Contributions are welcome! To add a new region or fix existing data:

1. Fork the repository.
2. Edit the appropriate JSON file(s) under `data/`.
3. Add or update tests in `terraform.tftest.hcl`.
4. Run `terraform test` to verify all tests pass.
5. Submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Build5Nines LLC
