output "repository" {
  value       = local.output_set.repository
  description = "The id, arn, clone_url_ssh, etc... of CodeCommit Repository"
}

output "build_project" {
  value       = local.output_set.build_project
  description = "The arn, name, environment, etc... of CodeBuild Project"
}

output "deploy" {
  value       = local.output_set.deploy
  description = "The id, arn, name, etc... of CodeDeploy app , config, group"
}

output "pipeline" {
  value       = local.output_set.pipeline
  description = "The id, arn of CodePipeline"
}
