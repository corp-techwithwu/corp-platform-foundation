
###############################################################################
# Input Variables
###############################################################################

variable "environment" {
  description = "Environment name (e.g. prod, nonprod)."
  type        = string
  default     = "nonprod"
}

variable "location" {
  description = <<DESC
Default Azure region used for ALZ-related artifacts, such as:
- Policy managed identities
- Deployment scripts
DESC
  type        = string
  default     = "centralus"
}

variable "platform_subscription_id" {
  description = "Subscription ID that will be placed under the Platform management group."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "enable_telemetry" {
  description = "Enable Azure Verified Module (AVM) telemetry via modtm."
  type        = bool
  default     = false
}

variable "corp_platform_root_group_name" {
  type        = string
  description = "The Root subscription of the management group"
}


variable "subscription_placement_destroy_behavior" {
  description = <<DESC
Controls where the subscription is moved when the ALZ subscription
placement is destroyed (i.e. when the subscription is removed from
the Platform management group).

Valid options:
- parent
- intermediate_root
- custom
- default

The default (`intermediate_root`) is the safest option:
during `terraform destroy`, the subscription is moved back to the
intermediate root management group created in this stack, instead of
falling into the tenant-root default management group where policies
would immediately stop applying.
DESC
  type        = string
  default     = "intermediate_root"

  validation {
    condition     = contains(["parent", "intermediate_root", "custom", "default"], var.subscription_placement_destroy_behavior)
    error_message = "Value must be one of: parent, intermediate_root, custom, default."
  }
}
