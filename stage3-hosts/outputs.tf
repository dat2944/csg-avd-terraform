output "session_host_names" { value = local.host_names }
output "mgmt_vm_name" { value = azurerm_windows_virtual_machine.mgmt.name }
output "mgmt_vm_id" { value = azurerm_windows_virtual_machine.mgmt.id }
output "local_admin_password" {
  value     = random_password.local_admin.result
  sensitive = true
}
