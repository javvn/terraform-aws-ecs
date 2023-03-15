resource "aws_codebuild_project" "this" {
  for_each = local.resource_context.build

  name          = each.value.name
  description   = each.value.description
  badge_enabled = each.value.badge_enabled
  service_role  = aws_iam_role.this["CODEBUILD"].arn

  artifacts {
    type                   = each.value.artifacts.type
    artifact_identifier    = each.value.artifacts.artifact_identifier
    override_artifact_name = each.value.artifacts.override_artifact_name
  }

  environment {
    type            = each.value.environment.type
    image           = each.value.environment.image
    compute_type    = each.value.environment.compute_type
    privileged_mode = each.value.environment.privileged_mode

    dynamic "environment_variable" {
      for_each = each.value.environment.environment_variable

      content {
        name  = environment_variable.key
        type  = environment_variable.value.type
        value = environment_variable.value.value
      }

    }
  }

  source {
    type     = each.value.source.type
    location = aws_codecommit_repository.this[each.key].arn
  }

  logs_config {
    cloudwatch_logs {
      group_name  = each.value.log_configs.cloudwatch_logs.group_name
      stream_name = each.value.log_configs.cloudwatch_logs.stream_name
      status      = each.value.log_configs.cloudwatch_logs.status
    }
  }

  depends_on = [
    aws_iam_role.this,
    aws_codecommit_repository.this,
  ]
}