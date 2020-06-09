variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = "rap"
}

variable "location" {
  description = "The Azure location where all resources in this example should be created"
  default = "East US"
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
