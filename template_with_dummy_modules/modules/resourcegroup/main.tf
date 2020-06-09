provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "rap" {
    name     = "${var.prefix}-rg"
    location = "${var.location}"
}
