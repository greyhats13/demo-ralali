data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc-cidr-block

  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = var.vpc_name
  }
}

#Node Subnet
resource "aws_subnet" "nodes_subnet" {
  count             = length(var.nodes_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.nodes_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "nodes-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

#Public Subnet
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.public_subnet_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "public-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}


#Internet Gatway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "Internet-Gateway"
  }
}

resource "aws_eip" "eip" {
  count = 3
  vpc   = true

  tags = {
    Name = "Elastic IP Nat"
  }
}

# Nat Gateway allocated to elastic ip's
resource "aws_nat_gateway" "nat-gw" {
  count         = length(aws_subnet.public_subnet)
  allocation_id = element(aws_eip.eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = {
    Name = "NAT-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

#Public Route Table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public RT"
  }
}

#Nodes Route Table
resource "aws_route_table" "node-rt" {
  count  = length(var.nodes_subnet_cidr)
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.nat-gw.*.id, count.index)
  }

  tags = {
    Name = "Nodes-RT-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_route_table_association" "public_route_assc" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "node_route_assc" {
  count          = length(aws_subnet.nodes_subnet)
  subnet_id      = element(aws_subnet.nodes_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.node-rt.*.id, count.index)
}
