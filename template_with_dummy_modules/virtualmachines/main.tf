provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "virtualmachines" {
    source          = "../modules/virtualmachines"
    prefix          = "${var.prefix}"
  #  zones           = "${var.av_zones}"
    admin_username  = "${var.admin_username}"
    vm_count        = "${var.vm_count}"
  #  vm_size            = "${var.sku}"
    admin_password  = "${var.admin_password}"
}
