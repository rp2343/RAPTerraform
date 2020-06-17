# Configure the Microsoft Azure Provider.
provider "azurerm" {
  version = "~>2.0"
  features {
  }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}RG"
  location = var.location
  tags     = var.tags
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  count = length(var.vnet_prefix)
  name  = "${var.prefix}Vnet${count.index + 1}"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  address_space = [element(var.vnet_prefix, count.index)["ip"]]

  #  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  count = length(var.subnet_prefix)
  name  = element(var.subnet_prefix, count.index)["name"]

  #  subnet_names         = ["${var.subnet_names}-az1", "${var.subnet_names}-az2", "${var.subnet_names}-az3"]
  resource_group_name = azurerm_resource_group.rg.name

  #  virtual_network_name = azurerm_virtual_network.vnet.name
  virtual_network_name = element(azurerm_virtual_network.vnet.*.name, count.index)
  address_prefix       = element(var.subnet_prefix, count.index)["ip"]
}

# Create public IP
#resource "azurerm_public_ip" "publicip" {
#  count               = "${var.vm_count}"
#  name                = "${var.prefix}ip${count.index + 1}"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.rg.name
#  sku                 = "Standard"
#  zones               = ["${element(var.av_zones,(count.index))}"]
#  allocation_method   = "Static"
#  tags                = var.tags
#}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}nic${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  #  network_security_group_id = azurerm_network_security_group.nsg.id
  tags                          = var.tags
  enable_accelerated_networking = "true"

  ip_configuration {
    name                          = "${var.prefix}config${count.index + 1}"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    private_ip_address_allocation = "dynamic"
    #   public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id,count.index)}"
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}vm${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_D4s_v3"

  #  zones                 = [element(split(",", var.av_zone), count.index)]
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  zones = [element(var.av_zones, count.index)]
  tags  = var.tags

  storage_os_disk {
    name              = "${var.prefix}OsDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = var.sku[var.location]
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}VM${count.index + 1}"
    admin_username = var.admin_username
    #  admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/id_rsa.pub")
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}

