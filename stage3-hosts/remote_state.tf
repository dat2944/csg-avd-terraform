data "terraform_remote_state" "stage1" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = "tfstate"
    key                  = "${var.client_name}/stage1-foundation.tfstate"
    use_azuread_auth     = true
  }
}

data "terraform_remote_state" "stage2" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = "tfstate"
    key                  = "${var.client_name}/stage2-storage-avd.tfstate"
    use_azuread_auth     = true
  }
}

locals {
  s1 = data.terraform_remote_state.stage1.outputs
  s2 = data.terraform_remote_state.stage2.outputs
}
