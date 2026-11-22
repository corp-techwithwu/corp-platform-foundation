
data "azapi_resource" "corp_platform_root_group" {
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = var.corp_platform_root_group_name
}

###############################################################################
# Intermediate Root Management Group
# - Stable name (no random suffix)
# - Protected from accidental deletion
###############################################################################

resource "azapi_resource" "intermediate_root_mg" {
  type      = "Microsoft.Management/managementGroups@2023-04-01"
  parent_id = "/"
  name      = local.intermediate_root_mg_name

  body = {
    properties = {
      displayName = "${upper(local.organization)} ${upper(var.environment)} Root"
      details = {
        parent = {
          id = data.azapi_resource.corp_platform_root_group.id
        }
      }
    }
  }

  response_export_values = []

  retry = {
    error_message_regex = [
      "AuthorizationFailed", # Avoids a eventual consistency issue where a recently created management group is not yet available for a GET operation.
      "Permission to Microsoft.Management/managementGroups on resources of type 'Write' is required on the management group or its ancestors."
    ]
  }

  lifecycle {
    prevent_destroy = true
  }

  timeouts {
    create = "60m"
    read   = "60m"
    delete = "5m"
    update = "5m"
  }
}

###############################################################################
# ALZ Architecture
# AVM Pattern: Azure/avm-ptn-alz/azurerm
#
# - Does NOT overwrite library content
# - Explicitly places the Platform subscription into the Platform MG
# - Uses conservative destroy behavior:
#   subscriptions fall back to the intermediate root MG, not tenant root
#
# IMPORTANT:
# The ALZ provider reads the library via data sources during `plan`
# and DOES NOT support `depends_on`.
# Ordering is enforced by passing computed values through
# `management_groups_dependencies`.
###############################################################################

module "alz_architecture" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.22.0"

  # Matches alz.alz_architecture_definition.yaml in the library
  architecture_name = "alz"

  # MG name only – no /providers/... prefix
  parent_resource_id = local.alz_parent_resource_id

  # Region for policy managed identities and deployment scripts
  location = local.alz_location

  # Previously declared but never wired up
  enable_telemetry = var.enable_telemetry

  # Ensure the intermediate root MG, Platform MG, and hierarchy settings
  # exist before the ALZ provider reads the hierarchy.
  management_groups_dependencies = [
    azapi_resource.intermediate_root_mg.id
  ]

  subscription_placement_destroy_behavior = var.subscription_placement_destroy_behavior

  # Non-compliance message template.
  # `{enforcementMode}` is expanded by the provider-level substitution.
  policy_assignment_non_compliance_message_settings = {
    default_message = "This resource {enforcementMode} be compliant with the assigned policy."
    merge_mode      = "replace"
  }

  policy_assignments_to_modify = {
    # Azure Landing Zones
    landingzones = {
      policy_assignments = {
        Enable-DDoS-VNET = {
          parameters = {
            effect = jsonencode({ value = "Disabled" })
          }
        }
      }
    }
    connectivity = {
      policy_assignments = {
        Enable-DDoS-VNET = {
          parameters = {
            effect = jsonencode({ value = "Disabled" })
          }
        }
      }
    }
  }
}