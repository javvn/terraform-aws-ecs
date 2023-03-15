locals {
  context               = yamldecode(file(var.config_file)).context
  code_series_context   = yamldecode(templatefile(var.config_file, local.context)).code_series
  iam_context           = yamldecode(templatefile(var.config_file, local.context)).iam
  ssm_parameter_context = yamldecode(templatefile(var.config_file, local.context)).ssm_parameter

  remote_path_context = {
    network   = "${path.module}/${yamldecode(file(var.config_file)).remote_path.network}"
    log       = "${path.module}/${yamldecode(file(var.config_file)).remote_path.log}"
    container = "${path.module}/${yamldecode(file(var.config_file)).remote_path.container}"
  }

  common_tags = {
    Env       = local.context.env
    Owner     = local.context.owner
    Project   = local.context.project
    Terraform = local.context.terraform
  }

  resource_context = {
    role          = local.iam_context.role
    policy        = local.iam_context.policy
    repository    = local.code_series_context.repository
    build         = local.code_series_context.build
    deploy        = local.code_series_context.deploy
    pipeline      = local.code_series_context.pipeline
    ssm_parameter = local.ssm_parameter_context
  }

  ssm_parameter = {
    s3_bucket        = data.aws_ssm_parameter.s3_bucket.value
    ecs_cluster_name = { for k, v in data.aws_ssm_parameter.ecs_cluster : k => v.value }
    ecs_service_name = { for k, v in data.aws_ssm_parameter.ecs_service : k => v.value }
  }

  remote_state = { for k, v in data.terraform_remote_state.this : k => v["outputs"] }

  search_set = {
    repository = [
      "id",
      "arn",
      "repository_id",
      "clone_url_ssh",
      "clone_url_http",
      "default_branch",
      "repository_name",
    ]
    build_project = [
      "arn",
      "name",
      "artifacts",
      "environment",
    ]
    deploy = {
      app = [
        "id",
        "arn",
        "name",
        "application_id",
      ]
      config = [
        "id",
      ]
      group = [
        "id",
        "arn",
      ]
    }
    pipeline = [
      "id",
      "arn",
    ]
  }

  output_set = {
    repository    = { for r_k, r_v in aws_codecommit_repository.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.repository, c_k) } }
    build_project = { for r_k, r_v in aws_codebuild_project.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.build_project, c_k) } }
    deploy = {
      app    = { for r_k, r_v in aws_codedeploy_app.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.deploy.app, c_k) } }
      config = { for r_k, r_v in aws_codedeploy_deployment_config.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.deploy.config, c_k) } }
      group  = { for r_k, r_v in aws_codedeploy_deployment_group.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.deploy.group, c_k) } }
    }
    pipeline = { for r_k, r_v in aws_codepipeline.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.pipeline, c_k) } }
  }

}