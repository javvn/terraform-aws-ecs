data "aws_ssm_parameter" "s3_bucket" {
  name = local.resource_context.ssm_parameter.s3.bucket.name
}

resource "aws_codepipeline" "this" {
  for_each = local.resource_context.pipeline

  name     = each.value.name
  role_arn = aws_iam_role.this[each.value.role_index].arn

  artifact_store {
    location = local.ssm_parameter.s3_bucket
    type     = each.value.artifacts.type
  }

  dynamic "stage" {
    for_each = each.value.stages

    content {
      name = stage.value.stage_name

      action {
        category         = stage.value.action.category
        name             = stage.value.action.name
        owner            = stage.value.action.owner
        provider         = stage.value.action.provider
        version          = stage.value.action.version
        input_artifacts  = stage.value.action.input_artifacts
        output_artifacts = stage.value.action.output_artifacts
        configuration    = stage.value.action.configuration
      }
    }
  }

  depends_on = [
    aws_iam_role.this,
    aws_codebuild_project.this,
    aws_codecommit_repository.this,
    aws_codedeploy_deployment_group.this,
  ]
}