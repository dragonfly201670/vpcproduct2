data "aws_vpc_ipam_pool" "fugropublicpool" {
  filter {
    name   = "locale"
    values = [data.aws_region.current.name]
  }
  filter {
    name   = "description"
    values = ["public pool ireland"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

data "aws_region" "current" {

}

data "aws_availability_zones" "current" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  partition       = cidrsubnets(aws_vpc.public_vpc.cidr_block, 1, 1)
  private_subnets = cidrsubnets(local.partition[0], 1, 2, 2)
  public_subnets  = cidrsubnets(local.partition[1], 1, 2, 2)
}

resource "aws_vpc" "public_vpc" {
  ipv4_ipam_pool_id = data.aws_vpc_ipam_pool.fugropublicpool.id
  ipv4_netmask_length = var.netmask
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = var.vpcname
  }
}

resource "aws_subnet" "public_subnets" {
  for_each                = toset(data.aws_availability_zones.current.names)
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = local.public_subnets[index(data.aws_availability_zones.current.names, each.key)]
  map_public_ip_on_launch = "false"
  availability_zone       = tolist(data.aws_availability_zones.current.names)[index(data.aws_availability_zones.current.names, each.value)]
  tags = {
    Name = "public-subnet-${each.key}"
  }
  depends_on = [aws_vpc.public_vpc]
}

resource "aws_subnet" "private_subnets" {
  for_each                = toset(data.aws_availability_zones.current.names)
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = local.private_subnets[index(data.aws_availability_zones.current.names, each.key)]
  map_public_ip_on_launch = "false"
  availability_zone       = tolist(data.aws_availability_zones.current.names)[index(data.aws_availability_zones.current.names, each.value)]
  tags = {
    Name = "private-subnet-${each.key}"
  }
  depends_on = [aws_vpc.public_vpc]
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id     = aws_vpc.public_vpc.id
  depends_on = [aws_vpc.public_vpc]
}

resource "aws_eip" "nat_eip" {

}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = values(aws_subnet.public_subnets)[0].id
  depends_on    = [aws_subnet.public_subnets]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.public_vpc.id
  tags = {
    Name = "private-route-table"
  }
  depends_on = [aws_vpc.public_vpc, aws_nat_gateway.nat_gateway]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.public_vpc.id
  tags = {
    Name = "public-route-table"
  }
  depends_on = [aws_vpc.public_vpc, aws_internet_gateway.internet_gateway]
}

resource "aws_route" "privateroute" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
  depends_on = [ aws_route_table.private_route_table, aws_nat_gateway.nat_gateway ]
}

resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
  depends_on = [ aws_route_table.public_route_table, aws_internet_gateway.internet_gateway ]
}

resource "aws_route_table_association" "publicrtassociation" {
  for_each = aws_subnet.public_subnets
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_route_table.id
  depends_on = [ aws_subnet.public_subnets, aws_route_table.public_route_table ]
}

resource "aws_route_table_association" "privatertassociation" {
  for_each = aws_subnet.private_subnets
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_route_table.id
  depends_on = [ aws_route_table.private_route_table, aws_subnet.private_subnets ]
}


