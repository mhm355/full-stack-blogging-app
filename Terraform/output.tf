output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "security_group_ids" {
  value = {
    cluster_sg = aws_security_group.blogging_cluster_sg.id
    node_sg    = aws_security_group.blogging_node_sg.id
  }
}


output "vpc_id" {
  value = aws_vpc.blogging_vpc.id
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}
output "eks_nodes_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "cluster_name" {
  value = aws_eks_cluster.blogging_eks.name
}
output "node_group_name" {
  value = aws_eks_node_group.blogging_nodegroup.node_group_name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.blogging_eks.endpoint
}



