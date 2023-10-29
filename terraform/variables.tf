variable "ami_id" {
  default = "ami-021c3acb0745bbbe6"
  description = "AMI ID for Ubuntu 22.04"
}

variable "instance_type" {
  default = "t3.medium"
  description = "vCPU: 2, Mem: 4GB"
}
