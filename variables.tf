variable "netmask" {
  type    = number
  default = 24
  validation {
    condition     = var.netmask >= 22 && var.netmask <= 26
    error_message = "Please provide value of subnet mask from 22 to 26 only"
  }
}

variable "vpcname" {
  type    = string
  default = "testpublic"
}

