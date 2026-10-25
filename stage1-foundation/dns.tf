# Point the VNet at the two Entra DS domain controllers. This must be in
# place before any session host or management VM is created (Stage 3).
resource "azurerm_virtual_network_dns_servers" "entrads" {
  virtual_network_id = azurerm_virtual_network.avd.id
  dns_servers        = azurerm_active_directory_domain_service.this.initial_replica_set[0].domain_controller_ip_addresses
}
