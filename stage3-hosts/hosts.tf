resource "random_password" "local_admin" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

# Token the AVD agent uses to register each host to the host pool.
# To add hosts after it expires: terraform apply -replace=azurerm_virtual_desktop_host_pool_registration_info.this
resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  hostpool_id     = local.s2.host_pool_id
  expiration_date = timeadd(timestamp(), "${var.registration_token_hours}h")
  lifecycle {
    ignore_changes = [expiration_date]
  }
}

locals {
  host_names = [for i in range(var.session_host_count) : "${var.prefix}-VM-${i}"]
  mgmt_name  = "${var.prefix}-MGMT-0"
}

# ---------- Session hosts ----------
resource "azurerm_network_interface" "host" {
  for_each            = toset(local.host_names)
  name                = "NIC-${each.key}"
  location            = local.s1.location
  resource_group_name = local.s1.resource_group_name
  tags                = var.tags
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.s1.hosts_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "host" {
  for_each              = toset(local.host_names)
  name                  = each.key
  computer_name         = each.key
  location              = local.s1.location
  resource_group_name   = local.s1.resource_group_name
  size                  = var.session_host_size
  admin_username        = var.local_admin_username
  admin_password        = random_password.local_admin.result
  network_interface_ids = [azurerm_network_interface.host[each.key].id]
  license_type          = "Windows_Client" # AVD multi-session license benefit
  secure_boot_enabled   = true
  vtpm_enabled          = true
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }

  boot_diagnostics {}
}

# Guide section 6 step 10: join to Entra Domain Services.
resource "azurerm_virtual_machine_extension" "host_domain_join" {
  for_each                   = azurerm_windows_virtual_machine.host
  name                       = "DomainJoin"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    Name    = local.s1.domain_name
    User    = var.domain_join_upn
    Restart = "true"
    Options = "3"
  })
  protected_settings = jsonencode({
    Password = var.domain_join_password
  })
  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

# Install the AVD agent + bootloader and register to the host pool.
resource "azurerm_virtual_machine_run_command" "host_avd_agent" {
  for_each           = azurerm_windows_virtual_machine.host
  name               = "Install-AVDAgent"
  location           = local.s1.location
  virtual_machine_id = each.value.id
  source {
    script = file("${path.module}/scripts/Install-AVDAgent.ps1")
  }
  protected_parameter {
    name  = "RegistrationToken"
    value = azurerm_virtual_desktop_host_pool_registration_info.this.token
  }
  depends_on = [azurerm_virtual_machine_extension.host_domain_join]
  lifecycle {
    ignore_changes = [protected_parameter]
  }
}

# ---------- Management VM (guide section 13) ----------
resource "azurerm_network_interface" "mgmt" {
  name                = "NIC-${local.mgmt_name}"
  location            = local.s1.location
  resource_group_name = local.s1.resource_group_name
  tags                = var.tags
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = local.s1.hosts_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "mgmt" {
  name                  = local.mgmt_name
  computer_name         = local.mgmt_name
  location              = local.s1.location
  resource_group_name   = local.s1.resource_group_name
  size                  = var.mgmt_vm_size
  admin_username        = var.local_admin_username
  admin_password        = random_password.local_admin.result
  network_interface_ids = [azurerm_network_interface.mgmt.id]
  secure_boot_enabled   = true
  vtpm_enabled          = true
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}
}

resource "azurerm_virtual_machine_extension" "mgmt_domain_join" {
  name                       = "DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.mgmt.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    Name    = local.s1.domain_name
    User    = var.domain_join_upn
    Restart = "true"
    Options = "3"
  })
  protected_settings = jsonencode({
    Password = var.domain_join_password
  })
  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

# Guide section 13.1: RSAT / GPMC on the management VM.
resource "azurerm_virtual_machine_run_command" "mgmt_rsat" {
  name               = "Install-RSAT"
  location           = local.s1.location
  virtual_machine_id = azurerm_windows_virtual_machine.mgmt.id
  source {
    script = "Install-WindowsFeature -Name GPMC, RSAT-AD-PowerShell, RSAT-ADDS-Tools, RSAT-DNS-Server -IncludeManagementTools"
  }
  depends_on = [azurerm_virtual_machine_extension.mgmt_domain_join]
}
