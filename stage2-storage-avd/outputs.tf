output "storage_account_name" { value = azurerm_storage_account.fslogix.name }
output "storage_account_id" { value = azurerm_storage_account.fslogix.id }
output "share_name" { value = azurerm_storage_share.profiles.name }
output "file_host" { value = azurerm_storage_account.fslogix.primary_file_host }
output "fslogix_unc_path" {
  value = "\\\\${azurerm_storage_account.fslogix.primary_file_host}\\${azurerm_storage_share.profiles.name}"
}
output "host_pool_id" { value = azurerm_virtual_desktop_host_pool.this.id }
output "host_pool_name" { value = azurerm_virtual_desktop_host_pool.this.name }
output "workspace_name" { value = azurerm_virtual_desktop_workspace.this.name }
