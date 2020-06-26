variable "location" {
}

variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
}

variable "admin_password" {
  type        = string
  description = "Password must meet Azure complexity requirements"
}

variable "av_zones" {
  default = ["1", "2", "3"]
}

variable "vm_count" {
  description = "Count number of VMs"
  default     = "6"
}

variable "vm_size" {
  description = "VM Size"
  default     = "Standard_D15s_v2"
}

variable "prefix" {
  type    = string
  default = "rock"
}

variable "tags" {
  type = map(string)

  default = {
    Environment = "Test"
    Dept        = "Engineering"
  }
}

variable "sku" {
  default = {
    westus = "7.8"
    eastus = "7.8"
  }
}

variable "vnet_prefix" {
#  type = list(string)
  default = [
    {
      ip = "10.0.0.0/16"
    },
  ]
}

variable "subnet_prefix" {
#  type = list(string)
  default = [
    {
      ip   = "10.0.1.0/24"
      name = "subnet-1"
    },
    {
      ip   = "10.0.2.0/24"
      name = "subnet-2"
    },
    {
      ip   = "10.0.3.0/24"
      name = "subnet-3"
    },
  ]
}

