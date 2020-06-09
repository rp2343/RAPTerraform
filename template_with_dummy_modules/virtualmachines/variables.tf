variable "admin_username" {
  description = "administrator user name"
  default     = "hadruser"
}

variable "admin_password" {
  description = "Password"
  default = "Microsoft1234$"  
}

variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = "rap"
}

variable "av_zones" {
    default = ["1", "2", "3"]
}

variable "vm_count" {
    description = "Count number of VMs"
    default = "6"
}

variable "sku" {
    description = "VM SKU"
    default = "Standard_D4s_v3"
}
