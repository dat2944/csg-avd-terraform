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

variable "domain_join_upn" {
  description = "Runs the script; must be in AAD DC Administrators."
  type        = string
}
variable "domain_join_password" {
  type      = string
  sensitive = true
}
variable "block_clipboard" {
  description = "Guide 17.5: block clipboard redirection."
  type        = bool
  default     = true
}
variable "block_drive_redirection" {
  description = "Guide 17.5: block drive redirection."
  type        = bool
  default     = true
}
