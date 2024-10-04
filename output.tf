output "aws_availability_zones" {
  value = data.aws_availability_zones.current.names
}

output "publicipampools" {
  value = data.aws_vpc_ipam_pool.fugropublicpool.id
}


output "cidrbreakdown" {
  value = local.partition
}

output "public_subnets" {
  value = local.public_subnets
}

output "private_subnets" {
  value = local.private_subnets
}

output "public_subnets_ids" {
  value = values(aws_subnet.private_subnets)[0].id
}