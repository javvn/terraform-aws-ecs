resource "aws_ecs_cluster" "this" {
  for_each = local.resource_context.ecs

  name = each.key

  configuration {
    execute_command_configuration {
      logging = each.value.configuration.execute_command_configuration.logging

      log_configuration {
        cloud_watch_encryption_enabled = each.value.configuration.execute_command_configuration.log_configuration.cloud_watch_encryption_enabled
        cloud_watch_log_group_name     = each.value.configuration.execute_command_configuration.log_configuration.cloud_watch_log_group_name
      }
    }
  }

  tags = merge(local.common_tags, { Name = each.value.name })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  for_each = local.resource_context.ecs

  cluster_name       = each.key
  capacity_providers = each.value.fargate_capacity_providers.capacity_providers


  dynamic "default_capacity_provider_strategy" {
    for_each = each.value.fargate_capacity_providers.default_capacity_provider_strategy

    content {
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
      capacity_provider = default_capacity_provider_strategy.key
    }
  }

  depends_on = [aws_ecs_cluster.this]
}

resource "aws_ecs_task_definition" "this" {
  for_each = local.resource_context.ecs_task_definition

  family                   = each.key
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  network_mode             = each.value.network_mode
  task_role_arn            = each.value.task_role_arn
  execution_role_arn       = each.value.execution_role_arn
  requires_compatibilities = each.value.requires_compatibilities

  container_definitions = jsonencode([for k, v in each.value.container_definitions : merge(v, {
    image : "${aws_ecr_repository.this[each.key].repository_url}:latest"
  })])

  runtime_platform {
    operating_system_family = each.value.runtime_platform.operating_system_family
    cpu_architecture        = each.value.runtime_platform.cpu_architecture
  }

  tags = merge(local.common_tags, { Name = each.value.family })

  depends_on = [aws_ecr_repository.this]
}

resource "aws_ecs_service" "this" {
  for_each = local.resource_context.ecs_service

  cluster         = aws_ecs_cluster.this[each.value.ref.cluster].arn
  task_definition = aws_ecs_task_definition.this[each.value.ref.task_definition].arn

  name                               = each.key
  launch_type                        = each.value.launch_type
  desired_count                      = each.value.desired_count
  platform_version                   = each.value.platform_version
  scheduling_strategy                = each.value.scheduling_strategy
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = each.value.health_check_grace_period_seconds

  deployment_controller {
    type = each.value.deployment_controller_type
  }

  deployment_circuit_breaker {
    enable   = each.value.deployment_circuit_breaker.enable
    rollback = each.value.deployment_circuit_breaker.rollback
  }

  network_configuration {
    subnets          = local.remote_state.network.subnet_groups[each.value.ref.subnet_name].ids
    security_groups  = [local.remote_state.network.security_groups[each.value.ref.security_group_name].id]
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancer

    content {
      target_group_arn = each.key == "front" ? aws_lb_target_group.front[load_balancer.key].arn : aws_lb_target_group.back[load_balancer.key].arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  tags = merge(local.common_tags, { Name = each.value.name })

  depends_on = [
    aws_lb_listener.back,
    aws_lb_listener.front,
    aws_ecs_cluster.this,
    aws_lb_target_group.back,
    aws_lb_target_group.front,
    aws_ecs_task_definition.this
  ]
}

resource "aws_ssm_parameter" "ecs_cluster_names" {
  for_each = local.resource_context.ssm_parameter.ecs.cluster_names

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_ecs_cluster.this[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_ecs_cluster.this]
}

resource "aws_ssm_parameter" "ecs_service_names" {
  for_each = local.resource_context.ssm_parameter.ecs.service_names

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_ecs_service.this[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_ecs_service.this]
}

resource "aws_ssm_parameter" "task_definition_names" {
  for_each = local.resource_context.ssm_parameter.ecs.task_definition_names

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_ecs_task_definition.this[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_ecs_task_definition.this]
}