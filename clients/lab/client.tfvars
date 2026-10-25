# ================= CSG lab (commercial) =================
# One file per client. Every stage reads this file; each stage uses the
# values it declares and ignores the rest (Terraform prints a warning
# for the unused ones, which is expected).

# ---------- Tenant / cloud ----------
cloud_environment = "public" # "usgovernment" for GCC High
tenant_id         = "<TENANT_ID>"
subscription_id   = "<SUBSCRIPTION_ID>"
client_name       = "lab" # must match this folder name

# ---------- State (Phase 3) ----------
state_resource_group  = "RG-TFSTATE"
state_storage_account = "sttfstatecsglab01"

# ---------- Naming / location ----------
prefix   = "CSG"
location = "eastus2"
tags = {
  solution    = "Contractor Secure Gateway"
  environment = "lab"
}

# ---------- Stage 1: network, Entra DS, groups ----------
vnet_address_space     = ["10.50.0.0/16"]
entrads_subnet_prefix  = "10.50.0.0/24"
hosts_subnet_prefix    = "10.50.1.0/24"
domain_name            = "csglab.yourdomain.com"
entrads_sku            = "Standard"
notification_emails    = ["you@yourdomain.com"]
create_dc_admins_group = true
admin_upns             = ["admin@yourdomain.com"]
user_upns              = ["csgtest1@yourdomain.com", "csgtest2@yourdomain.com"]

# ---------- Stage 2: storage + AVD ----------
storage_account_name            = "stcsgfslogixlab01"
share_name                      = "fslogix-profiles"
enable_private_endpoint         = true
host_pool_friendly_name         = "Contractor Secure Gateway"
max_sessions_per_host           = 8
avd_service_principal_object_id = "<OBJECT_ID>" # Phase 5.1

# ---------- Stage 3: hosts ----------
session_host_count = 2
session_host_size  = "Standard_D4s_v5"
image_offer        = "windows-11"
image_sku          = "win11-24h2-avd" # from Phase 2.3
mgmt_vm_size       = "Standard_B2ms"
domain_join_upn    = "svc-csg-join@yourdomain.com" # Phase 7
# domain_join_password comes from the pipeline secret DOMAIN_JOIN_PASSWORD

# ---------- Stage 4: config ----------
block_clipboard         = true
block_drive_redirection = true
