variable "service_name"{
  
  default = "bccc83ea57f44920978bf95c43ef77b1"
}

variable "deployment_instances" {

  description = "deployment name"
  type        = string
  default     = "salt-deploy-test"
}

variable "deployment_image" {

  description = "image name"
  type        = string
  default     = "AlmaLinux 9"

}

variable "deployment_flavor" {

  description = "machine type"
  type        = string
  default     = "d2-8"
}

variable "instance_count" {

  description = " number of instances"
  type        = number
  default     = 1
}


variable "pub_key" {
  type = string
  default = "/Users/admin/.ssh/id_rsa_sivamac.pub"
}

variable "pvt_key" {
   type = string
   default = "/Users/admin/.ssh/id_rsa_sivamac"

}