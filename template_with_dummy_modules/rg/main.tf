provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "resourcegroup" {
    source = "../modules/resourcegroup"
    location = "${var.location}"
    prefix = "${var.prefix}"
}
