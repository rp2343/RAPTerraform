# Configure the Microsoft Azure Provider.
provider "azurerm" {
  version = "~>2.0"
  features {
  }
}

data "azurerm_subscription" "current" {}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}RG"
  location = var.location
  tags     = var.tags
}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

resource "azurerm_user_assigned_identity" "msi" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "${var.prefix}msi"
}

resource "azurerm_role_assignment" "msirole" {
#  name               = azurerm_virtual_machine.jumpvm.name
  scope              = data.azurerm_subscription.current.id
  role_definition_id = "${data.azurerm_subscription.current.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = azurerm_user_assigned_identity.msi.principal_id
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  count = length(var.vnet_prefix)
  name  = "${var.prefix}Vnet${count.index + 1}"
  address_space = [element(var.vnet_prefix, count.index)["ip"]]
  #  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  count = length(var.subnet_prefix)
  name  = element(var.subnet_prefix, count.index)["name"]

  #  subnet_names         = ["${var.subnet_names}-az1", "${var.subnet_names}-az2", "${var.subnet_names}-az3"]
  resource_group_name = azurerm_resource_group.rg.name

  #  virtual_network_name = azurerm_virtual_network.vnet.name
  virtual_network_name = element(azurerm_virtual_network.vnet.*.name, count.index)
  address_prefix       = element(var.subnet_prefix, count.index)["ip"]
}

# Create public IP
#resource "azurerm_public_ip" "publicip" {
#  count               = "${var.vm_count}"
#  name                = "${var.prefix}ip${count.index + 1}"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.rg.name
#  sku                 = "Standard"
#  zones               = ["${element(var.av_zones,(count.index))}"]
#  allocation_method   = "Static"
#  tags                = var.tags
#}

# Create JumpVm public IP
resource "azurerm_public_ip" "jumppip" {
#  count               = "${var.vm_count}"
  name                = "jumppip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  zones               = ["${element(var.av_zones,(0))}"]
  allocation_method   = "Static"
  tags                = var.tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "jumpnsg" {
  name                = "jumpNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface for Jump VM
resource "azurerm_network_interface" "jumpnic" {
#  count               = var.vm_count
  name                = "jumpnic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                          = var.tags
  enable_accelerated_networking = "true"

  ip_configuration {
    name                          = "jumpip"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, 0)
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = element(azurerm_public_ip.jumppip.*.id, 0)
  }
}

resource "azurerm_network_interface_security_group_association" "jumpnsglink" {
  network_interface_id      = azurerm_network_interface.jumpnic.id
  network_security_group_id = azurerm_network_security_group.jumpnsg.id
}


# Create a Jump VM 
resource "azurerm_virtual_machine" "jumpvm" {
#  count               = var.vm_count
  name                = "jumpvm"
  location            = var.location
  depends_on		= [azurerm_user_assigned_identity.msi]
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.jumpnic.id]
  vm_size               = "Standard_D4s_v3"
  identity {
    type = "UserAssigned"
    identity_ids = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${azurerm_user_assigned_identity.msi.name}"]
  }

  zones = [element(var.av_zones, 0)]
  tags  = var.tags

  storage_os_disk {
    name              = "jumposDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = var.sku[var.location]
    version   = "latest"
  }

  os_profile {
    computer_name  = "jumpvm"
    admin_username = var.admin_username
    custom_data = file("jumpvmsetup.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/id_rsa.pub")
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}nic${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  #  network_security_group_id = azurerm_network_security_group.nsg.id
  tags                          = var.tags
  enable_accelerated_networking = "true"

  ip_configuration {
    name                          = "${var.prefix}config${count.index + 1}"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    private_ip_address_allocation = "dynamic"
    #   public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id,count.index)}"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vmnsg" {
  name                = "${var.prefix}NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "10.0.0.0/8"
  }

  security_rule {
    name                       = "Azure"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "Internet"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "Internet"
  }
}



resource "azurerm_network_interface_security_group_association" "vmnsglink" {
  count                     = var.vm_count
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.vmnsg.id
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}vm${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = var.vm_size
  depends_on            = [azurerm_user_assigned_identity.msi]
  zones = [element(var.av_zones, count.index)]
  tags  = var.tags
  identity {
    type = "UserAssigned"
    identity_ids = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${azurerm_user_assigned_identity.msi.name}"]
  }


  storage_os_disk {
    name              = "${var.prefix}OsDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = var.sku[var.location]
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}VM${count.index + 1}"
    admin_username = var.admin_username
    #  admin_password = var.admin_password
    custom_data = file("install_strongswan.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/id_rsa.pub")
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}