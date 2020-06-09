variable "resource_group_name" {
  description   = "Resource Group name"
}

variable "location" {
  description   = "The Azure location where all resources should be created"
}

variable "size" {
  description   = "VM SKU"
}

variable "zones" {
  description   = "VM Zones"
}

variable "vm_count" {
  description = "VM Count"  
}

variable "admin_username" {
  description   = "Admin Username"
}

variable "tags" {
  description   = "Tags"
}

variable "vm_name" {
  description   = "Prefix of VM"
}

variable "network_interface_ids" {
  description = "Network Interface IDs"  
}

variable "source_image_reference" {
  description = "Source Image reference"  
}

variable "os_disk" {
  description = "OS Disk"  
}
