# Azure Region Helper Terraform Module from Build5Nines

An opinionated region and abbreviation helper for enterprise multi-region Terraform deployments.

**Problem it solves:** Multi-region Terraform gets messy fast — primary/secondary regions, short codes, paired regions, allowed regions, data-residency zones, and naming abbreviations. This module wraps all of that into a single, enterprise-focused interface.

## Usage

```terraform
module "regions" {
  source = "Build5Nines/region-map/azure"

  primary_region  = "eastus"
  strategy        = "paired-region"
  allowed_regions = ["eastus", "westus", "centralus"]
}
```

### Outputs

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

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `primary_region` | `string` | _(required)_ | The primary Azure region (e.g. `"eastus"` or `"East US"`). |
| `secondary_region` | `string` | `""` | Explicit secondary region. Required when `strategy = "custom"`. |
| `strategy` | `string` | `"paired-region"` | Strategy for selecting the secondary region: `"paired-region"` or `"custom"`. |
| `allowed_regions` | `list(string)` | `[]` | Approved regions for policy compliance. Empty = all allowed. |
| `region_abbreviations` | `map(string)` | `{}` | Custom region → abbreviation overrides. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `primary` | `object` | Primary region details (name, short, display_name, geography, compliance_zone). |
| `secondary` | `object` | Secondary region details (same shape as primary). |
| `strategy` | `string` | The strategy used for secondary region selection. |
| `paired_region` | `string` | Azure's designated paired region (regardless of strategy). |
| `is_allowed` | `bool` | Whether the primary region is in the allowed list. |
| `is_secondary_allowed` | `bool` | Whether the secondary region is in the allowed list. |
| `allowed_regions` | `map(object)` | Enriched map of each allowed region with metadata. |
| `is_cross_geography` | `bool` | Whether primary and secondary are in different geographies. |
| `is_cross_zone` | `bool` | Whether primary and secondary are in different compliance zones. |
| `region_abbreviations` | `map(string)` | Full region → abbreviation map (with overrides merged). |

## Enterprise Use Cases

### Landing Zones

```terraform
module "regions" {
  source = "Build5Nines/region-map/azure"

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

### Disaster Recovery

```terraform
module "dr_regions" {
  source = "Build5Nines/region-map/azure"

  primary_region = "uksouth"
}

# Outputs:
# module.dr_regions.primary.name   = "uksouth"
# module.dr_regions.secondary.name = "ukwest"
# module.dr_regions.is_cross_geography = false
```

### Multi-Region Naming

```terraform
module "regions" {
  source = "Build5Nines/region-map/azure"

  primary_region = var.location
}

locals {
  primary_rg_name   = "rg-${var.app}-${module.regions.primary.short}-${var.env}"
  secondary_rg_name = "rg-${var.app}-${module.regions.secondary.short}-${var.env}"
}
# rg-myapp-eus-prd / rg-myapp-wus-prd
```

### Custom Secondary Region

```terraform
module "regions" {
  source = "Build5Nines/region-map/azure"

  primary_region   = "eastus"
  secondary_region = "North Europe"
  strategy         = "custom"
}

# module.regions.secondary.name      = "northeurope"
# module.regions.is_cross_zone       = true   (Americas ↔ EMEA)
# module.regions.is_cross_geography  = true   (United States ↔ Europe)
# module.regions.paired_region       = "westus"  (still available)
```

## Data Sources

Region data is stored in `data/`:

- **region_abbr.json** — Canonical region name → short abbreviation.
- **region_pair.json** — Canonical region name → Azure paired region.
- **region_display_names.json** — Canonical region name → display name.
- **region_geography.json** — Canonical region name → geography/country.

## How it differs from AVM Azure Regions Data

| Concern | AVM Regions Data | This Module |
|---------|------------------|-------------|
| Focus | Raw Azure region metadata | Enterprise deployment decisions |
| Paired regions | Data only | Strategy-driven selection |
| Abbreviations | Not included | Built-in with overrides |
| Policy compliance | Not included | `allowed_regions` + `is_allowed` |
| Data residency | Not included | Geography + compliance zones |
| DR helpers | Not included | Cross-geography/zone flags |
