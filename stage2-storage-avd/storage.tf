resource "azurerm_storage_account" "fslogix" {
  name                            = var.storage_account_name
  resource_group_name             = local.s1.resource_group_name
  location                        = local.s1.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Needed once by Stage 4 to set NTFS ACLs with the storage key.
  shared_access_key_enabled = true

  # Left on for the build; turned off in Phase 12 once the private endpoint is proven.
  public_network_access_enabled = true

  # Guide section 8: Entra Domain Services as the identity source.
  azure_files_authentication {
    directory_type = "AADDS"
  }

  tags = var.tags
}

resource "azurerm_storage_share" "profiles" {
  name               = var.share_name
  storage_account_id = azurerm_storage_account.fslogix.id
  quota              = var.share_quota_gb
  access_tier        = "TransactionOptimized"
  enabled_protocol   = "SMB"
}

locals {
  share_scope = "${azurerm_storage_account.fslogix.id}/fileServices/default/fileshares/${azurerm_storage_share.profiles.name}"
}

# ---------- Guide section 9: share-level RBAC ----------
resource "azurerm_role_assignment" "fslogix_users" {
  scope                = local.share_scope
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = local.s1.group_ids.fslogix_users
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "avd_admins" {
  scope                = local.share_scope
  role_definition_name = "Storage File Data SMB Share Elevated Contributor"
  principal_id         = local.s1.group_ids.avd_admins
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "dc_admins" {
  scope                = local.share_scope
  role_definition_name = "Storage File Data SMB Share Elevated Contributor"
  principal_id         = local.s1.group_ids.dc_admins
  principal_type       = "Group"
}

# ---------- Private endpoint ----------
locals {
  file_zone = var.cloud_environment == "usgovernment" ? "privatelink.file.core.usgovcloudapi.net" : "privatelink.file.core.windows.net"
}

resource "azurerm_private_dns_zone" "file" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = local.file_zone
  resource_group_name = local.s1.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "link-${var.prefix}-avd"
  resource_group_name   = local.s1.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file[0].name
  virtual_network_id    = local.s1.vnet_id
}

resource "azurerm_private_endpoint" "file" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "PE-${var.storage_account_name}-file"
  location            = local.s1.location
  resource_group_name = local.s1.resource_group_name
  subnet_id           = local.s1.hosts_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-file"
    private_connection_resource_id = azurerm_storage_account.fslogix.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.file[0].id]
  }
}
