resource "azurerm_active_directory_domain_service" "this" {
  name                = var.domain_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = var.tags

  domain_name               = var.domain_name
  sku                       = var.entrads_sku
  domain_configuration_type = "FullySynced"
  filtered_sync_enabled     = false

  initial_replica_set {
    subnet_id = azurerm_subnet.entrads.id
  }

  notifications {
    additional_recipients = var.notification_emails
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
    ntlm_v1_enabled         = false
    tls_v1_enabled          = false
  }

  # Provisioning takes 45-90 minutes.
  timeouts {
    create = "3h"
    update = "2h"
    delete = "1h"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.entrads,
    azuread_group_member.dc_admins,
  ]
}
