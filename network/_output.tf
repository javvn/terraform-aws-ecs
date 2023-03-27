output "vpc" {
  value       = local.output_set.vpc
  description = "The  arn, cidr_block, etc.. of VPC"
}

output "subnet_groups" {
  value       = local.output_set.subnet_groups
  description = "The  id, arn, name, cidr_block etc.. of Subnet Group"
}

output "route" {
  value       = local.output_set.route_table
  description = "The  id of Route Table"
}

output "security_groups" {
  value       = local.output_set.security_groups
  description = "The  id, arn, name, etc.. of Security Group"
}

output "vpc_endpoint" {
  value       = local.output_set.vpc_endpoint
  description = "The  service_name of VPC Endpoint"
}

