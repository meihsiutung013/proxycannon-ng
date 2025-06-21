variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 24.04 LTS"
  type        = string
  default     = "ami-0d1b5a8c13042c939"  # Ubuntu 24.04 LTS en us-east-1
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "subnet_id" {
  description = "Subnet ID where instances will be created"
  type        = string
  default     = "subnet-05eb2dd4ee1cc8c9c"  # Replace with your actual subnet ID
}

variable "aws_priv_key" {
  description = "Path to AWS private key"
  type        = string
  default     = "~/.ssh/proxycannon.pem"
}