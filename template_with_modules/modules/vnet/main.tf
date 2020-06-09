provider "azurerm" {
  version = "~>2.0"
  features {}
}
resource "azurerm_virtual_network" "vnet" {
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  name                  = "${var.vnet_name}"
  tags                  = "${var.tags}"
  address_space         = "${var.address_space}"
}
