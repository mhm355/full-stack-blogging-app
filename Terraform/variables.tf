variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (Development / Staging / Production)"
  type        = string
  default     = "development"
}

variable "blogging_vpc_cidr_block" {
  description = "CIDR block for the Blogging VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "blogging-tf-eks"
}

variable "node_group_desired_size" {
  type    = number
  default = 1
}
variable "node_group_min_size" {
  type    = number
  default = 1
}
variable "node_group_max_size" {
  type    = number
  default = 2
}
variable "instance_types" {
  type    = string
  default = "t3.micro"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "ubuntu"
}
