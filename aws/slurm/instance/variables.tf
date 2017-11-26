variable "private_key_path" {
  description = "Enter the path to the SSH Private Key to run provisioner."
  default = "~/.ssh/terraform_aws"
}

variable "ami_name" {
}

variable "disk_size" {
  default = 8
}

variable "count" {
  default = 1
}

variable "group_name" {
  description = "Group name becomes the base of the hostname of the instance"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "instance_type" {
  description = "AWS region to launch servers."
  default     = "p2.xlarge"
}

variable "subnet_id" {
  description = "ID of the AWS VPC subnet to use"
}

variable "key_pair_id" {
  description = "ID of the keypair to use for SSH"
}

variable "security_group_id" {
  description = "ID of the VPC security group to use for network"
}

variable "provisioner_remote_exec" {
  description = "Command that is executed after instance came up"
  default = "date"
}
