output "vpc" {
  value = local.output_set.vpc
}

output "subnet_groups" {
  value = local.output_set.subnet_groups
}

output "route" {
  value = local.output_set.route_table
}

output "security_groups" {
  value = local.output_set.security_groups
}

output "vpc_endpoint" {
  value = local.output_set.vpc_endpoint
}

