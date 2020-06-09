provider "azurerm" {
  version = "~>2.0"
  features {}
}
resource "azurerm_linux_virtual_machine" "vms" {
  resource_group_name       = "${var.resource_group_name}"
  location                  = "${var.location}"
  name                      = "${var.vm_name}"
  network_interface_ids     = "${var.nic}"
  admin_username            = "${var.admin_username}"
  size                      = "${var.size}"
  zones                     = "${var.zones}"
  tags                      = "${var.tags}"
  vm_count                  = "${var.vm_count}"
  source_image_reference    = "${var.source_image_reference}"
  os_disk                   = "${var.os_disk}"
}
