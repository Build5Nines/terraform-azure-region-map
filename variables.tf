# #######################################################
# Azure Region Helper Module
#
# An opinionated region and abbreviation helper for
# enterprise multi-region Terraform deployments.
#
# Source:
# https://github.com/Build5Nines/terraform-azure-region-map
#
# Author: Chris Pietschmann (https://pietschsoft.com)
# Copyright (c) 2026 Build5Nine LLC
# #######################################################

variable "primary_region" {
  description = "The primary Azure region (e.g. 'eastus' or 'East US')."
  type        = string
}

variable "secondary_region" {
  description = "Explicit secondary Azure region. Required when strategy is 'custom'. Ignored for other strategies."
  type        = string
  default     = ""
}

variable "strategy" {
  description = <<-EOT
    Strategy for selecting the secondary region:
      - "paired-region" (default) — Use Azure's designated regional pair.
      - "custom"                  — Use the value of secondary_region.
  EOT
  type        = string
  default     = "paired-region"

  validation {
    condition     = contains(["paired-region", "custom"], var.strategy)
    error_message = "strategy must be one of: paired-region, custom."
  }
}

variable "allowed_regions" {
  description = "List of Azure regions approved for deployment (policy compliance). When empty, all regions are considered allowed."
  type        = list(string)
  default     = []
}

variable "region_abbreviations" {
  description = <<-EOT
    Optional map of region → abbreviation overrides.
    Keys may be display names ("East US") or canonical names ("eastus").
    Example: { "eastus" = "east", "westus" = "west" }
  EOT
  type        = map(string)
  default     = {}
}
