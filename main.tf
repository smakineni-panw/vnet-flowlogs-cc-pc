terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Adjust to "~> 3.11.0" or latest when upgrading provider
    }
  }
}

# Use a data source to get the current client configuration
data "azurerm_client_config" "current" {}

provider "azurerm" {
  features {}
  # Use the subscription_id and tenant_id from the data source
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

##########################
# Resource Group
##########################
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-biz"
  location = var.location
  tags     = var.tags
}

##########################
# Virtual Network
##########################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}-biz"
  address_space       = [var.virtual_network_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

##########################
# Network Security Group (NSG) for Flow Logs
##########################
resource "azurerm_network_security_group" "flowlog_nsg" {
  name                = "${var.subnet_name}-nsg-biz"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

##########################
# Subnet
##########################
resource "azurerm_subnet" "flowlog_subnet" {
  name                 = "${var.subnet_name}-biz"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
  # Add Microsoft.Storage service endpoint to the subnet
  service_endpoints    = ["Microsoft.Storage"]
}

##########################
# Subnet NSG Association
##########################
resource "azurerm_subnet_network_security_group_association" "flowlog_nsg_association" {
  subnet_id                 = azurerm_subnet.flowlog_subnet.id
  network_security_group_id = azurerm_network_security_group.flowlog_nsg.id
}

##########################
# Storage Account
##########################
resource "azurerm_storage_account" "flowlogs" {
  name                     = "${var.storage_account_name}biz"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Uncomment these lines only after confirming your provider supports them
  # allow_blob_public_access   = false
  # https_traffic_only_enabled = true

  tags = var.tags

  # Added to comply with Azure Policy "Storage accounts should restrict network access"
  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [azurerm_subnet.flowlog_subnet.id]
    bypass                     = ["AzureServices"] # Required for Network Watcher to write flow logs
  }
}

##########################
# Network Watcher (Data Source - to use existing default)
##########################
data "azurerm_network_watcher" "nw" {
  # Azure typically creates a Network Watcher named NetworkWatcher_<region> in NetworkWatcherRG
  name                = "NetworkWatcher_${replace(var.location, " ", "")}"
  resource_group_name = "NetworkWatcherRG"
}

##########################
# Log Analytics Workspace
##########################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.log_analytics_workspace_name}-biz"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = 30 # Adjust as needed
  tags                = var.tags
}

##########################
# Network Watcher Flow Log
##########################
resource "azurerm_network_watcher_flow_log" "nsg_flowlog" {
  name                      = "${var.subnet_name}-nsg-flowlog-biz"
  network_watcher_name      = data.azurerm_network_watcher.nw.name # Referencing data source
  resource_group_name       = data.azurerm_network_watcher.nw.resource_group_name # Referencing data source
  network_security_group_id = azurerm_network_security_group.flowlog_nsg.id
  storage_account_id        = azurerm_storage_account.flowlogs.id
  enabled                   = true
  version                   = 2

  retention_policy {
    days    = 7
    enabled = true
  }

  traffic_analytics {
    enabled                = true
    workspace_id           = azurerm_log_analytics_workspace.law.workspace_id
    workspace_region       = azurerm_resource_group.rg.location
    workspace_resource_id  = azurerm_log_analytics_workspace.law.id
    interval_in_minutes    = 10
  }

  tags = var.tags
}
