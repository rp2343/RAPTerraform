provider "azurerm" {
  version = "~>2.0"
  features {}
}
resource "azurerm_subnet" "subnet" {
    resource_group_name     = "${var.resource_group_name}"
    virtual_network_name    = "${var.vnet_name}"
    location                = "${var.location}"
    name                    = "${var.name}"
    address_prefix          = "${var.address_prefixes}"
    tags                    = "${var.tags}"
    subnet_count            = "${var.subnet_count}"
}
