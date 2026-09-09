variable "name_prefix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "scale_out_policy_arn" {
  type = string
}

variable "scale_in_policy_arn" {
  type = string
}

variable "cpu_high_threshold" {
  type    = number
  default = 70
}

variable "cpu_low_threshold" {
  type    = number
  default = 20
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "min_healthy_instances" {
  description = "Alert if in-service instance count drops below this"
  type        = number
  default     = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
