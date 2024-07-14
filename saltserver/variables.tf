variable "service_name"{
  default = "~/.ovh/service_name"
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
  default = "~/.ssh/id_rsa.pub"
}

variable "pvt_key" {
   type = string
   default = "~/.ssh/id_rsa"

}