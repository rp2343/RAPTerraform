
variable "resource_group_name" {
  description = "Resource Group name"
}

variable "location" {
  description = "The Azure location where all resources should be created"
}

variable "vnet_name" {
  description = "Virtual Network Name"
}

variable "name" {
  description = "Subnet Names"
}

variable "subnet_count" {
  description = "Subnet Count"
}

variable "address_prefix" {
  description = "Address prefixes for subnets"
}

variable "tags" {
  description = "Tags"
}

