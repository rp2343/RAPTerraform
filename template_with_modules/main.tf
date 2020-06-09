provider "azurerm" {
  version = "~>2.0"
  features {
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.prefix}-${var.environment}"
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  tags                = var.tags
  vnet_name           = "${azurerm_resource_group.resource_group.name}-vnet"
  address_space       = var.address_space
}

module "subnet" {
  subnet_count        = length(var.subnet_prefix)
  source              = "./modules/subnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  vnet_name           = module.vnet.vnet_name
  tags                = var.tags
  name                = element(var.subnet_prefix, module.subnet.subnet_count.index)["name"]
#  name                = "${lookup(element(var.subnet_prefix, subnet_count.index), "name")}"

  #  subnet_names          = ["${var.subnet_names}-az1", "${var.subnet_names}-az2", "${var.subnet_names}-az3"]
  address_prefix = element(var.subnet_prefix, subnet_count.index)["ip"]
}

#resource "azurerm_network_interface" "nic" {
#    name                = "${azurerm_resource_group.resource_group.name}-1"
#    resource_group_name = "${azurerm_resource_group.resource_group.name}"
#    location            = "${var.location}"
#    tags                = "${var.tags}"
#    enable_accelerated_networking = "true"
#    ip_configuration {
#    name                          = "${azurerm_resource_group.resource_group.name}-ip"
#    subnet_id                     = modules.subnet.subnet.id
#    private_ip_address_allocation = "Dynamic"
#  }
#}

module "vms" {
  source                = "./modules/vms"
  vm_count		= var.vm_count
  vm_name               = "${azurerm_resource_group.resource_group.name}-${vm_count.index + 1}"
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = "$[azurerm_network_interface.nic[vm_count.index].id]"
  tags                  = var.tags
  location              = var.location
  size                  = var.size
  zones                 = [element(var.zones, count.index)]
  admin_username        = var.admin_username

  #admin_ssh_key {
  #  username    = "${var.admin_username}"
  #  public_key  = file("~/.ssh/id_rsa.pub")
  #}

  source_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

