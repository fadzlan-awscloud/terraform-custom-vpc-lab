# 1. Define the Custom VPC Network Space
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "production-vpc"
  }
}

# 2. Deploy an Internet Gateway for Public Routing Entry
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "prod-igw"
  }
}

# 3. Create Public Subnet 1 (Availability Zone A)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}

# 4. Build a Public Route Table pointing to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 5. Attach the Public Route Table to Public Subnet 1
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# ================================================================= #
# 1. HIGH AVAILABILITY EXTENSION: AVAILABILITY ZONE B
# ================================================================= #

# Public Subnet 2 (AZ-B) - The second landing zone for our Load Balancer
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-1b" }
}

# Attach Public Subnet 2 to our existing Public Route Table
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ================================================================= #
# 2. PRIVATE APPLICATION TIER (Completely hidden from the Internet)
# ================================================================= #

# Private Subnet 1 (AZ-A) - Where Flask App Instance 1 will live
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-southeast-1a"

  tags = { Name = "private-subnet-1a" }
}

# Private Subnet 2 (AZ-B) - Where Flask App Instance 2 will live
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-southeast-1b"

  tags = { Name = "private-subnet-1b" }
}

# ================================================================= #
# 3. ROUTING VIA THE NAT GATEWAY (Outbound-only updates for App Nodes)
# ================================================================= #

# Allocate a Static Public IP (Elastic IP) for our NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# Deploy the NAT Gateway inside Public Subnet 1
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id # Lives in public to talk out, shields the private

  tags = { Name = "prod-nat-gateway" }
}

# Create a Brand New Route Table for the Private Tier
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  # ROUTING RULE: Any outbound traffic (0.0.0.0/0) goes to the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = { Name = "private-route-table" }
}

# Associate Private Subnets to the NAT Gateway Route Table
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}