aws_region = "us-east-1"

environment = "staging"

blogging_vpc_cidr_block = "10.0.0.0/16"

public_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24"]
private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]

cluster_name = "blogging-eks"

instance_types = "c7i-flex.large"
node_group_desired_size = 1
node_group_min_size     = 1
node_group_max_size     = 2
