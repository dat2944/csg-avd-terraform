locals {
  rg_name   = "RG-${var.prefix}-AVD"
  vnet_name = "VNET-${var.prefix}-AVD"
}

resource "azurerm_resource_group" "avd" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

# ---------- Network ----------
resource "azurerm_virtual_network" "avd" {
  name                = local.vnet_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  address_space       = var.vnet_address_space
  tags                = var.tags

  # DNS servers are set by azurerm_virtual_network_dns_servers (dns.tf)
  # once Entra DS is up, so don't manage them here.
  lifecycle {
    ignore_changes = [dns_servers]
  }
}

resource "azurerm_subnet" "entrads" {
  name                 = "SNET-EntraDS"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = [var.entrads_subnet_prefix]
}

resource "azurerm_subnet" "hosts" {
  name                 = "SNET-AVD-Hosts"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = [var.hosts_subnet_prefix]
}

# Entra DS subnet NSG: Microsoft's management rules. Removing these puts
# the managed domain into an unhealthy state.
resource "azurerm_network_security_group" "entrads" {
  name                = "NSG-${var.prefix}-EntraDS"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = var.tags

  security_rule {
    name                       = "AllowPSRemoting"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRD"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "entrads" {
  subnet_id                 = azurerm_subnet.entrads.id
  network_security_group_id = azurerm_network_security_group.entrads.id
}

# Session host NSG: no inbound rules. AVD uses reverse connect, so hosts
# need no public inbound access; Azure's default rules block Internet inbound.
resource "azurerm_network_security_group" "hosts" {
  name                = "NSG-${var.prefix}-AVD-Hosts"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "hosts" {
  subnet_id                 = azurerm_subnet.hosts.id
  network_security_group_id = azurerm_network_security_group.hosts.id
}
