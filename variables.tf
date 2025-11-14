variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
  default     = "flowlog-rg"
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
  default     = "East US"
}

variable "virtual_network_name" {
  description = "Name of the Virtual Network."
  type        = string
  default     = "flowlog-vnet"
}

variable "virtual_network_address_space" {
  description = "Address space for the Virtual Network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  description = "Name of the subnet for flow logs."
  type        = string
  default     = "flowlog-subnet"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "storage_account_name" {
  description = "Name of the Storage Account for flow logs (must be globally unique, consist of lowercase letters and numbers, and be between 3 and 24 characters long)."
  type        = string
  default     = "flowlogsvnetpc" # Change this to a unique name adhering to the rules
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
  default     = "flowlog-law"
}

variable "log_analytics_workspace_sku" {
  description = "SKU for the Log Analytics Workspace (e.g., 'PerGB2018', 'Free', 'Standard')."
  type        = string
  default     = "PerGB2018"
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    Environment = "Dev"
    Project     = "NetworkFlowLogs"
    Owner       = "smakineni" # Added owner tag
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID for resource deployment."
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID associated with the subscription."
  type        = string
}
