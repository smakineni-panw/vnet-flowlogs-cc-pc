##########################
# Virtual Machine
##########################

# Public IP for the VM (Removed to comply with policy)
# resource "azurerm_public_ip" "vm_public_ip" {
#   name                = "${var.vm_name}-public-ip"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Dynamic" # Or "Static" if a fixed IP is needed
#   tags                = var.tags
# }

# Network Interface for the VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.flowlog_subnet.id # Reference the subnet from main.tf
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.vm_public_ip.id # Removed to comply with policy
  }
}

# Associate NSG to the VM's Network Interface (so flow logs are captured)
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.flowlog_nsg.id # Reference the NSG from main.tf
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_B1s" # Smallest size for testing
  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false # Set to true if using SSH keys

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

##########################
# VM Specific Variables (only variables *unique* to vm.tf)
##########################
variable "vm_name" {
  description = "Name of the Virtual Machine."
  type        = string
  default     = "flowlog-vm"
}

variable "vm_admin_username" {
  description = "Admin username for the Virtual Machine."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin password for the Virtual Machine."
  type        = string
  sensitive   = true
}

##########################
# VM Specific Outputs
##########################
# output "vm_public_ip_address" { # Removed as public IP is no longer attached
#   description = "The public IP address of the created Virtual Machine."
#   value       = azurerm_public_ip.vm_public_ip.ip_address
# }

output "vm_private_ip_address" {
  description = "The private IP address of the created Virtual Machine."
  value       = azurerm_network_interface.vm_nic.private_ip_address
}
