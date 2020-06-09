provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "networking" {
    source = "../modules/networking"
    location = "${var.location}"
    prefix = "${var.prefix}"
}
