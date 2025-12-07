data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "blogging_vpc" {
  cidr_block           = var.blogging_vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-blogging-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  
  vpc_id                  = aws_vpc.blogging_vpc.id
  cidr_block              = var.public_subnets_cidr[count.index]
  
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}


resource "aws_subnet" "private" {
  count                   = length(var.private_subnets_cidr)

  vpc_id                  = aws_vpc.blogging_vpc.id
  cidr_block              = var.private_subnets_cidr[count.index]
  
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.blogging_vpc.id

  tags = { Name = "${var.environment}-igw" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = { Name = "${var.environment}-nat-eip" }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id 
  depends_on    = [aws_internet_gateway.igw]
  tags = { Name = "${var.environment}-nat-gw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.blogging_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.environment}-public-rt" }
}
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.blogging_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.environment}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "blogging_cluster_sg" {
  vpc_id = aws_vpc.blogging_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.environment}-blogging-cluster-sg" }
}

resource "aws_security_group" "blogging_node_sg" {
  vpc_id = aws_vpc.blogging_vpc.id

  ingress {
    description = "Allow Node to Node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true # This allows traffic from other resources in the same SG
  }
  ingress {
    description = "Allow SSH access to Nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Allow traffic to NodePorts"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-blogging-node-sg" }
}


resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow HTTPS from Worker Nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.blogging_cluster_sg.id
  source_security_group_id = aws_security_group.blogging_node_sg.id
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow communication from Cluster Control Plane"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.blogging_node_sg.id
  source_security_group_id = aws_security_group.blogging_cluster_sg.id
}