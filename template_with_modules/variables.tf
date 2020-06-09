variable "environment" {
  description = "Environment Name"
  default     = "test"
}

variable "prefix" {
  description = "Prefix Name"
  default     = "rap"
}

variable "location" {
  description = "The Azure location where all resources should be created"
  default     = "East US"
}

variable "address_space" {
  description = "Virtual Network address space"
  default     = ["10.0.0.0/16"]
}

#variable "subnet_count" {
#  description = "Subnet Count"
#}

variable "vm_count" {
  description = "VM Count"
  default     = 3
}



variable "size" {
  description = "VM SKU"
  default     = "Standard_D4s_v3"
}

variable "zones" {
  default = ["1", "2", "3"]
}

variable "admin_username" {
  description = "Admin Username"
  default     = "adminuser"
}

variable "tags" {
  description = "Tags"
  default     = "blacrock"
}

variable "subnet_prefix" {
  #  type = list(string)
  default = [
    {
      ip   = "10.0.1.0/24"
      name = "subnet-az1"
    },
    {
      ip   = "10.0.2.0/24"
      name = "subnet-az2"
    },
    {
      ip   = "10.0.3.0/24"
      name = "subnet-az3"
    },
  ]
}

