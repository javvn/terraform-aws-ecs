#output "remote_state" {
#  value = local.remote_state
#}

output "ecr" {
  value = local.output_set.ecr
}

output "ecs" {
  value = local.output_set.ecs
}

output "lb" {
  value = local.output_set.lb
}