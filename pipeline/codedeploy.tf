data "aws_ssm_parameter" "ecs_cluster" {
  for_each = local.resource_context.ssm_parameter.ecs.cluster_names

  name = each.value.name
}

data "aws_ssm_parameter" "ecs_service" {
  for_each = local.resource_context.ssm_parameter.ecs.service_names

  name = each.value.name
}

resource "aws_codedeploy_app" "this" {
  for_each = local.resource_context.deploy.app

  name             = each.value.name
  compute_platform = each.value.compute_platform
  tags             = merge(local.common_tags, { Name = each.value.name })
}

resource "aws_codedeploy_deployment_config" "this" {
  for_each = local.resource_context.deploy.config

  deployment_config_name = each.value.deployment_config_name
  compute_platform       = each.value.compute_platform

  traffic_routing_config {
    type = each.value.traffic_routing_config.type

    time_based_canary {
      interval   = each.value.traffic_routing_config.time_based_canary.interval
      percentage = each.value.traffic_routing_config.time_based_canary.percentage
    }
  }
}

resource "aws_codedeploy_deployment_group" "this" {
  for_each = local.resource_context.deploy.group

  app_name               = aws_codedeploy_app.this[each.key].name
  service_role_arn       = aws_iam_role.this[each.value.service_role_index].arn
  deployment_group_name  = each.value.group_name
  deployment_config_name = aws_codedeploy_deployment_config.this[each.key].deployment_config_name

  auto_rollback_configuration {
    enabled = each.value.auto_rollback_configuration.enabled
    events  = each.value.auto_rollback_configuration.events
    #    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = each.value.blue_green_deployment_config.deployment_ready_option.action_on_timeout
    }

    terminate_blue_instances_on_deployment_success {
      action                           = each.value.blue_green_deployment_config.terminate_blue_instances_on_deployment_success.action
      termination_wait_time_in_minutes = each.value.blue_green_deployment_config.terminate_blue_instances_on_deployment_success.termination_wait_time_in_minutes
    }
  }

  deployment_style {
    deployment_option = each.value.deployment_style.deployment_option
    deployment_type   = each.value.deployment_style.deployment_type
  }

  ecs_service {
    cluster_name = local.ssm_parameter[each.value.ecs_service.cluster_name_key][each.key]
    service_name = local.ssm_parameter[each.value.ecs_service.service_name_key][each.key]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [local.remote_state.container.lb.listener[each.key]["BLUE"].arn]
      }

      test_traffic_route {
        listener_arns = [local.remote_state.container.lb.listener[each.key]["GREEN"].arn]
      }

      dynamic "target_group" {
        for_each = local.remote_state.container.lb.target_group[each.key]

        content {
          name = target_group.value.name
        }
      }
    }
  }

  depends_on = [
    aws_iam_role.this,
    aws_codedeploy_app.this,
    aws_codedeploy_deployment_config.this,
  ]
}
