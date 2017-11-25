//  The region we will deploy our cluster into.
variable "region" {
  description = "Region to deploy into"
  //  The default below will be fine for many, but to make it clear for first
  //  time users, there's no default, so you will be prompted for a region.
  default = "us-east-1"
}

variable "public_key_name" {
  description = "Enter the name of the keypair to use"
}

variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default = "~/.ssh/terraform_aws.pub"
}
