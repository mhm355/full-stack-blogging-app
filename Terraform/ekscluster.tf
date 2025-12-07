resource "aws_eks_cluster" "blogging_eks" {
  name     = "${var.environment}-blogging-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id 
    security_group_ids = [aws_security_group.blogging_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.service_policy,
  ]

  tags = {
    Name        = "${var.environment}-blogging-eks-cluster"
    Environment = var.environment
  }
}

resource "aws_eks_node_group" "blogging_nodegroup" {
  cluster_name    = aws_eks_cluster.blogging_eks.name
  node_group_name = "${var.environment}-blogging-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  subnet_ids = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.blogging_lt.id
    version = "$Latest"
  }

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [aws_security_group.blogging_node_sg.id]
  }

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
  ]

  tags = {
    Name        = "${var.environment}-blogging-nodegroup"
    Environment = var.environment
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.blogging_eks.name
  addon_name = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"


  depends_on = [aws_eks_node_group.blogging_nodegroup]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role = aws_iam_role.eks_nodes.name
}

resource "aws_launch_template" "blogging_lt" {
  name_prefix   = "${var.environment}-blogging-lt"
  
  instance_type = var.instance_types 

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-blogging-node"
    }
  }
}
