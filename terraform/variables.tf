variable "region" {
  description = "AWS region (per the VLE-8 handout)"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "vle8-bluegreen-key"
}

variable "my_ip" {
  description = "Your current public IP, for restricting SSH access"
  type        = string
}

variable "eic_cidr" {
  description = "AWS EC2 Instance Connect service IP range for this region (from ip-ranges.json)"
  type        = string
  default     = "13.233.177.0/29"
}
