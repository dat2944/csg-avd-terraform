variable "cloud_environment" {
  description = "\"public\" (commercial) or \"usgovernment\" (GCC High)."
  type        = string
  default     = "public"
}
variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "prefix" {
  type    = string
  default = "CSG"
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "client_name" {
  description = "Client folder name under clients/; also the state key prefix."
  type        = string
}
variable "state_resource_group" { type = string }
variable "state_storage_account" { type = string }

variable "session_host_count" {
  type    = number
  default = 2
}
variable "session_host_size" {
  type    = string
  default = "Standard_D4s_v5"
}
variable "image_offer" {
  description = "windows-11 (no Office) or office-365 (with Microsoft 365 Apps)."
  type        = string
  default     = "windows-11"
}
variable "image_sku" {
  description = "Multi-session SKU, checked in Phase 2.3 (e.g. win11-24h2-avd, or win11-24h2-avd-m365 with office-365)."
  type        = string
  default     = "win11-24h2-avd"
}
variable "mgmt_vm_size" {
  type    = string
  default = "Standard_B2ms"
}
variable "local_admin_username" {
  type    = string
  default = "csgadmin"
}
variable "domain_join_upn" {
  description = "Domain join account (member of AAD DC Administrators), e.g. svc-csg-join@yourdomain.com."
  type        = string
}
variable "domain_join_password" {
  description = "Set by the pipeline from the secret variable DOMAIN_JOIN_PASSWORD."
  type        = string
  sensitive   = true
}
variable "registration_token_hours" {
  description = "Host pool registration token lifetime (1-720 hours)."
  type        = number
  default     = 24
}
