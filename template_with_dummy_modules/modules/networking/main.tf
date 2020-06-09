provider "azurerm" {
  version = "~>2.0"
  features {}
}

data "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
}

resource "azurerm_virtual_network" "vnet" {
#  source              = "Azure/vnet/azurerm"
  name           = "${var.prefix}vnet"
  location       = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "blackrock"
   }  
  subnet {
     name = "subnetaz1"
     address_prefix = "10.0.1.0/24"
  }
  subnet {
     name = "subnetaz2"
     address_prefix = "10.0.2.0/24"
  }
  subnet {
     name = "subnetaz3"
     address_prefix = "10.0.3.0/24"
  }
}

# Create subnet
#resource "azurerm_subnet" "subnet" {
#  count                = "${length(var.subnet_prefix)}"
#  name                 = "${lookup(element(var.subnet_prefix, count.index), "name")}"
#  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
#  virtual_network_name = "${var.prefix}vnet"
#  address_prefix       = "${lookup(element(var.subnet_prefix, count.index), "ip")}"
#}


