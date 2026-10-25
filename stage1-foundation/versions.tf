terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Partial backend: settings come from clients/<client>/backend.hcl
  # plus -backend-config="key=<client>/stage1-foundation.tfstate" at init.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  environment     = var.cloud_environment # "public" for commercial, "usgovernment" for GCC High
}

provider "azuread" {
  tenant_id   = var.tenant_id
  environment = var.cloud_environment == "usgovernment" ? "usgovernment" : "global"
}
