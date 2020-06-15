##refer to the existing RG
data "azurerm_resource_group" "rg" {
  name = "${var.prefix}-rg"
}

##refer to the existing VNET and Subnet
data "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}vnet"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
}

data "azurerm_subnet" "subnet" {
  name                 = "${data.azurerm_virtual_network.vnet.subnets[count.index]}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${data.azurerm_virtual_network.vnet.resource_group_name}"
  count = "${length(data.azurerm_virtual_network.vnet.subnets)}"
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  count               = "${var.vm_count}"
  name                = "${var.prefix}ip${count.index + 1}"
  location            = "${data.azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  zones               = ["${element(var.av_zones,(count.index))}"]
  allocation_method   = "Static"
  tags = {
    environment = "blackrock"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  count                     = "${var.vm_count}"
  name                      = "${var.prefix}nic${count.index + 1}"
  location                  = "${data.azurerm_resource_group.rg.location}"
  resource_group_name       = "${data.azurerm_resource_group.rg.name}"
  enable_accelerated_networking = "true"
  tags = {
    environment = "blackrock"
  }

  ip_configuration {
    name                          = "${var.prefix}config${count.index + 1}"
    subnet_id                     = "${element(data.azurerm_subnet.subnet.*.id,count.index)}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id,count.index)}"
  }
}

resource "azurerm_virtual_machine" "virtualmachines" {
  count               = "${var.vm_count}"
  name                = "${var.prefix}vm${count.index + 1}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  location            = "${data.azurerm_resource_group.rg.location}"
  vm_size             = "${var.sku}"
  zones               = ["${element(var.av_zones,(count.index))}"]
#  admin_username      = "${var.admin_username}"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]
  storage_os_disk {
    name              = "${var.prefix}OsDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.7"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}VM${count.index + 1}"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = "${file("install_strongswan.sh")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}
  

