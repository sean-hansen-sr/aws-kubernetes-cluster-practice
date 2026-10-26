# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Create an Internet Gateway (Required for the NAT Gateway to talk to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "main-igw" }
}

# 3. Create a Public Subnet (NAT Gateway Subnet)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet" }
}

# Create a Private Subnet (No Internet Gateway)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = { Name = "nat-eip" }
}

# Create the NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = { Name = "main-nat-gateway" }
}

# Route Table for Public Subnet (Routes directly to the Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-route-table" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnet (Routes outbound traffic to the NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private-route-table" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a Security Group
resource "aws_security_group" "private_sg" {
  name        = "private-ubuntu-sg"
  description = "Allow internal traffic"
  vpc_id      = aws_vpc.main.id
  
  # Allow TCP Port 179 (BGP)
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    self        = true
  }

  # Allow UDP Port 4789 (Calico VXLAN overlay network)
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  # Allow TCP Port 5473 (Calico Typha communication)
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    self        = true
  }

  # Allow TCP Port 6443 (Kubernetes API server)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  # Allow UDP Port 51820 & 51821 (Calico WireGuard encryption)
  ingress {
    from_port   = 51820
    to_port     = 51821
    protocol    = "udp"
    self        = true
  }

  # Allow IP-in-IP (IP Protocol 4) encapsulation
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "4" # Protocol 4 represents IP-in-IP
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ubuntu-sg"
  }
}
