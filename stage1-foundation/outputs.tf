output "resource_group_name" { value = azurerm_resource_group.avd.name }
output "location" { value = azurerm_resource_group.avd.location }
output "vnet_id" { value = azurerm_virtual_network.avd.id }
output "hosts_subnet_id" { value = azurerm_subnet.hosts.id }

output "domain_name" { value = azurerm_active_directory_domain_service.this.domain_name }
output "entrads_id" { value = azurerm_active_directory_domain_service.this.id }
output "entrads_dns_ips" {
  value = azurerm_active_directory_domain_service.this.initial_replica_set[0].domain_controller_ip_addresses
}

output "group_ids" {
  value = {
    avd_users     = azuread_group.avd_users.object_id
    avd_admins    = azuread_group.avd_admins.object_id
    fslogix_users = azuread_group.fslogix_users.object_id
    dc_admins     = local.dc_admins_group_id
  }
}
