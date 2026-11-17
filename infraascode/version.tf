###############################################################################
# Terraform & Provider Requirements
###############################################################################

terraform {
  required_version = "~> 1.17"

  backend "azurerm" {
    use_oidc = true
  }

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "~> 0.22.1"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.13.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.13"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }

    # The following three providers are required internally by the
    # avm-ptn-alz module. They must be declared explicitly in the root
    # module, otherwise `terraform init` will fail with missing provider
    # dependencies.
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
