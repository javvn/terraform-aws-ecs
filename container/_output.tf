#output "remote_state" {
#  value = local.remote_state
#}

output "ecr" {
  value       = local.output_set.ecr
  description = "The output for ECR"
}

output "ecs" {
  value       = local.output_set.ecs
  description = "The output for ECS"
}

output "lb" {
  value       = local.output_set.lb
  description = "The output for Load Balancer"
}