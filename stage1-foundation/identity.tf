# The "Domain Controller Services" service principal Entra DS runs under is
# created once per tenant in Phase 2 (az ad sp create --id 2565bd9d-...).

data "azuread_user" "admins" {
  for_each            = toset(var.admin_upns)
  user_principal_name = each.value
}

data "azuread_user" "users" {
  for_each            = toset(var.user_upns)
  user_principal_name = each.value
}

# ---------- AAD DC Administrators ----------
resource "azuread_group" "dc_admins" {
  count            = var.create_dc_admins_group ? 1 : 0
  display_name     = "AAD DC Administrators"
  description      = "Delegated Entra Domain Services administration and GPO management"
  security_enabled = true
}

data "azuread_group" "dc_admins_existing" {
  count            = var.create_dc_admins_group ? 0 : 1
  display_name     = "AAD DC Administrators"
  security_enabled = true
}

locals {
  dc_admins_group_id = var.create_dc_admins_group ? azuread_group.dc_admins[0].object_id : data.azuread_group.dc_admins_existing[0].object_id
}

resource "azuread_group_member" "dc_admins" {
  for_each         = data.azuread_user.admins
  group_object_id  = local.dc_admins_group_id
  member_object_id = each.value.object_id
}

# ---------- CSG groups (guide section 5) ----------
resource "azuread_group" "avd_users" {
  display_name     = "AVD - ${var.prefix} Users"
  mail_nickname    = "AVD-${var.prefix}-Users"
  description      = "Users allowed to access the Contractor Secure Gateway desktops"
  security_enabled = true
  members          = [for u in data.azuread_user.users : u.object_id]
}

resource "azuread_group" "avd_admins" {
  display_name     = "AVD - ${var.prefix} Admins"
  mail_nickname    = "AVD-${var.prefix}-Admins"
  description      = "Administrative users for AVD and FSLogix share permissions"
  security_enabled = true
  members          = [for u in data.azuread_user.admins : u.object_id]
}

resource "azuread_group" "fslogix_users" {
  display_name     = "FSLogix - ${var.prefix} Users"
  mail_nickname    = "FSLogix-${var.prefix}-Users"
  description      = "Users allowed to create and use FSLogix profiles"
  security_enabled = true
  members          = [for u in data.azuread_user.users : u.object_id]
}
