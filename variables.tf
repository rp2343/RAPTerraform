variable "location" {}

variable "admin_username" {
    type = "string"
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = "string"
    description = "Password must meet Azure complexity requirements"
}

variable "av_zone" {
    type = "list"
    default = ["1","2","3"]
}

variable "vm_count" {
    description = "Count number of VMs"
    default = "3"
}


variable "prefix" {
    type = "string"
    default = "blackrock"
}

variable "tags" {
    type = "map"

    default = {
        Environment = "Test"
        Dept = "Engineering"
  }
}

variable "sku" {
    default = {
        westus = "7.7"
        eastus = "7.7"
    }
}

variable "subnet_prefix" {
  type = "list"
  default = [
    {
      ip      = "10.0.1.0/24"
      name     = "subnet-1"
    },
    {
      ip      = "10.0.2.0/24"
      name     = "subnet-2"
    },
    {
      ip       = "10.0.3.0/24"
      name      = "subnet-3"
    }
   ]
}