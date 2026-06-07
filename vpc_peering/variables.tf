variable "environment" {
   type = string
   default = "dev"
}

variable "primary" {
    type = string
    default = "us-east-1"
  
}
variable "secondary" {
    type = string
    default = "us-west-2"
  
}

variable "primary_vpc_cider" {
    default = "10.0.0.0/16"
  
}

variable "secondary_vpc_cider" {
    default = "10.1.0.0/16"
  
}


variable "primary_key_name" {
    default = ""
    description = "Name of the ssh key pair for primary vpc instance"
    type = string
  
}

variable "secondary_key_name" {
    default = ""
    description = "Name of the ssh key pair for secondary vpc instance"
    type = string
  
}