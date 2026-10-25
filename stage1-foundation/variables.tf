# ---------- Tenant / cloud ----------
variable "cloud_environment" {
  description = "Azure cloud: \"public\" (commercial lab) or \"usgovernment\" (GCC High)."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "usgovernment"], var.cloud_environment)
    error_message = "cloud_environment must be \"public\" or \"usgovernment\"."
  }
}

variable "tenant_id" {
  description = "Entra tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Subscription the CSG environment is deployed into."
  type        = string
}

# ---------- Naming / location ----------
variable "prefix" {
  description = "Short client prefix used in resource names (e.g. CSG)."
  type        = string
  default     = "CSG"
}

variable "location" {
  description = "Azure region. Keep Entra DS, AVD and storage in the same region."
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    solution    = "Contractor Secure Gateway"
    environment = "lab"
  }
}

# ---------- Network ----------
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.50.0.0/16"]
}

variable "entrads_subnet_prefix" {
  description = "Dedicated subnet for Entra Domain Services. Nothing else goes here."
  type        = string
  default     = "10.50.0.0/24"
}

variable "hosts_subnet_prefix" {
  description = "Subnet for AVD session hosts and the management VM."
  type        = string
  default     = "10.50.1.0/24"
}

# ---------- Entra Domain Services ----------
variable "domain_name" {
  description = "Managed domain FQDN, e.g. csglab.yourdomain.com (a verified custom domain or subdomain of one)."
  type        = string
}

variable "entrads_sku" {
  description = "Entra DS SKU: Standard, Enterprise or Premium."
  type        = string
  default     = "Standard"
}

variable "notification_emails" {
  description = "Extra addresses that receive Entra DS health alerts."
  type        = list(string)
  default     = []
}

variable "create_dc_admins_group" {
  description = "Create the 'AAD DC Administrators' group. Set false if it already exists in the tenant."
  type        = bool
  default     = true
}

# ---------- Group membership ----------
variable "admin_upns" {
  description = "Admins added to AAD DC Administrators and AVD - CSG Admins."
  type        = list(string)
  default     = []
}

variable "user_upns" {
  description = "Test users added to AVD - CSG Users and FSLogix - CSG Users."
  type        = list(string)
  default     = []
}
