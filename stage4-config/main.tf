data "azurerm_storage_account" "fslogix" {
  name                = local.s2.storage_account_name
  resource_group_name = local.s1.resource_group_name
}

# Guide sections 10, 14, 15, 16, 17: NTFS ACLs, OU structure, GPOs.
# Runs on CSG-MGMT-0 as the domain join account (AAD DC Administrators),
# because creating OUs and GPOs needs that membership. Re-runs whenever
# the script or any parameter changes; the script is idempotent.
resource "azurerm_virtual_machine_run_command" "configure_csg" {
  name               = "Configure-CSG"
  location           = local.s1.location
  virtual_machine_id = local.s3.mgmt_vm_id
  run_as_user        = var.domain_join_upn
  run_as_password    = var.domain_join_password

  source {
    script = file("${path.module}/scripts/Configure-CSG.ps1")
  }

  parameter {
    name  = "Prefix"
    value = var.prefix
  }
  parameter {
    name  = "FileHost"
    value = local.s2.file_host
  }
  parameter {
    name  = "ShareName"
    value = local.s2.share_name
  }
  parameter {
    name  = "StorageAccountName"
    value = local.s2.storage_account_name
  }
  parameter {
    name  = "SessionHostNames"
    value = join(",", local.s3.session_host_names)
  }
  parameter {
    name  = "MgmtVmName"
    value = local.s3.mgmt_vm_name
  }
  parameter {
    name  = "BlockClipboard"
    value = var.block_clipboard ? "1" : "0"
  }
  parameter {
    name  = "BlockDrives"
    value = var.block_drive_redirection ? "1" : "0"
  }
  protected_parameter {
    name  = "StorageAccountKey"
    value = data.azurerm_storage_account.fslogix.primary_access_key
  }
}

output "run_command_output" {
  value = azurerm_virtual_machine_run_command.configure_csg.instance_view
}
