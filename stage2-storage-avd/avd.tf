# ---------- Guide section 6 ----------
resource "azurerm_virtual_desktop_host_pool" "this" {
  name                     = "HP-${var.prefix}-AVD"
  friendly_name            = var.host_pool_friendly_name
  location                 = local.s1.location
  resource_group_name      = local.s1.resource_group_name
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  maximum_sessions_allowed = var.max_sessions_per_host
  preferred_app_group_type = "Desktop"
  start_vm_on_connect      = true
  validate_environment     = false
  custom_rdp_properties    = var.rdp_properties
  tags                     = var.tags
}

resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = "DAG-${var.prefix}-AVD"
  friendly_name       = "${var.host_pool_friendly_name} Desktop"
  location            = local.s1.location
  resource_group_name = local.s1.resource_group_name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
  tags                = var.tags
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = "WS-${var.prefix}-AVD"
  friendly_name       = var.host_pool_friendly_name
  location            = local.s1.location
  resource_group_name = local.s1.resource_group_name
  tags                = var.tags
}

# The guide's "blank workspace" problem: the app group must be registered to the workspace.
resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = azurerm_virtual_desktop_workspace.this.id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

# Assign AVD - <prefix> Users to the desktop.
resource "azurerm_role_assignment" "desktop_users" {
  scope                = azurerm_virtual_desktop_application_group.desktop.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = local.s1.group_ids.avd_users
  principal_type       = "Group"
}

# Start VM on Connect: lets AVD power on deallocated hosts.
resource "azurerm_role_assignment" "power_on" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${local.s1.resource_group_name}"
  role_definition_name = "Desktop Virtualization Power On Contributor"
  principal_id         = var.avd_service_principal_object_id
  principal_type       = "ServicePrincipal"
}
