#output "remote_state" {
#  value = local.remote_state
#}

output "ecr" {
  value       = local.output_set.ecr
  description = "The id, arn, name, repo_url, etc.. of ECR repository public / private"
}

output "ecs" {
  value       = local.output_set.ecs
  description = "The id, arn, name, family, runtime_platform, etc.. of ECS cluster, service, task_definition"
}

output "lb" {
  value       = local.output_set.lb
  description = "The id, arn, name, etc.. of LB, target_group, listener"
}