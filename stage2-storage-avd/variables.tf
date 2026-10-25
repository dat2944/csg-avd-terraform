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

# ---------- Storage (guide sections 8-9) ----------
variable "storage_account_name" {
  description = "FSLogix storage account. 3-24 lowercase letters/digits, globally unique."
  type        = string
}
variable "share_name" {
  type    = string
  default = "fslogix-profiles"
}
variable "share_quota_gb" {
  type    = number
  default = 1024
}
variable "enable_private_endpoint" {
  description = "Private endpoint + private DNS zone for Azure Files."
  type        = bool
  default     = true
}

# ---------- AVD (guide section 6) ----------
variable "host_pool_friendly_name" {
  type    = string
  default = "Contractor Secure Gateway"
}
variable "max_sessions_per_host" {
  type    = number
  default = 8
}
variable "rdp_properties" {
  description = "Host pool RDP properties. Default blocks drive, clipboard, printer, COM, smart card and USB redirection (matches guide 17.5)."
  type        = string
  default     = "drivestoredirect:s:;redirectclipboard:i:0;redirectprinters:i:0;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1"
}
variable "avd_service_principal_object_id" {
  description = "Object ID of the tenant's 'Azure Virtual Desktop' service principal (app 9cdead84-a844-4324-93f2-b2e6bb768d07). Used for Start VM on Connect."
  type        = string
}
