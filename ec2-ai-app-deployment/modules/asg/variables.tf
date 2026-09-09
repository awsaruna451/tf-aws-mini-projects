variable "name_prefix" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type = string
}


variable "instance_profile_name" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = null
}

variable "root_volume_size" {
  type    = number
  default = 40
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "user_data" {
  description = "Rendered user_data script (base64 handled internally)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "target_group_arns" {
  type = list(string)
}
