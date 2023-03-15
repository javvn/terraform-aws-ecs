resource "aws_lb" "this" {
  for_each = local.resource_context.lb.L7

  name                       = each.value.name
  internal                   = each.value.internal
  ip_address_type            = each.value.ip_address_type
  load_balancer_type         = each.value.load_balancer_type
  enable_deletion_protection = each.value.enable_deletion_protection

  subnets         = each.value.subnets
  security_groups = each.value.security_groups

  tags = merge(local.common_tags, { Name = each.value.name })

  access_logs {
    bucket  = local.remote_state.log.s3.id
    prefix  = each.value.access_logs.prefix
    enabled = each.value.access_logs.enabled
  }
}

resource "aws_lb_target_group" "front" {
  for_each = local.resource_context.lb.target_group.front

  name                          = each.value.name
  port                          = each.value.port
  protocol                      = each.value.protocol
  protocol_version              = each.value.protocol_version
  vpc_id                        = each.value.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = each.value.load_balancing_algorithm_type

  health_check {
    enabled             = each.value.health_check.enabled
    protocol            = each.value.health_check.protocol
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    timeout             = each.value.health_check.timeout
    interval            = each.value.health_check.interval
  }

  tags = merge(local.common_tags, { Name = each.value.name })

  depends_on = [aws_lb.this]
}

resource "aws_lb_listener" "front" {
  for_each = local.resource_context.lb.listener.front

  load_balancer_arn = aws_lb.this["front"].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  tags              = merge(local.common_tags, { Name = each.value.name })

  default_action {
    type             = each.value.default_action.type
    target_group_arn = aws_lb_target_group.front[each.key].arn
  }

  depends_on = [aws_lb.this, aws_lb_target_group.front]
}

resource "aws_lb_target_group" "back" {
  for_each = local.resource_context.lb.target_group.back

  name                          = each.value.name
  port                          = each.value.port
  protocol                      = each.value.protocol
  protocol_version              = each.value.protocol_version
  vpc_id                        = each.value.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = each.value.load_balancing_algorithm_type

  health_check {
    enabled             = each.value.health_check.enabled
    protocol            = each.value.health_check.protocol
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    timeout             = each.value.health_check.timeout
    interval            = each.value.health_check.interval
  }

  tags = merge(local.common_tags, { Name = each.value.name })

  depends_on = [aws_lb.this]
}

resource "aws_lb_listener" "back" {
  for_each = local.resource_context.lb.listener.back

  load_balancer_arn = aws_lb.this["back"].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  tags              = merge(local.common_tags, { Name = each.value.name })

  default_action {
    type             = each.value.default_action.type
    target_group_arn = aws_lb_target_group.back[each.key].arn
  }

  depends_on = [aws_lb.this, aws_lb_target_group.back]
}

resource "aws_ssm_parameter" "front_listener_arns" {
  for_each = local.resource_context.ssm_parameter.lb.listener_arns.front

  name  = each.value.name
  type  = each.value.type
  value = aws_lb_listener.front[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_lb_listener.front]
}

resource "aws_ssm_parameter" "front_target_group_names" {
  for_each = local.resource_context.ssm_parameter.lb.target_group_names.front

  name  = each.value.name
  type  = each.value.type
  value = aws_lb_target_group.front[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_lb_target_group.front]
}

resource "aws_ssm_parameter" "back_listener_arns" {
  for_each = local.resource_context.ssm_parameter.lb.listener_arns.back

  name  = each.value.name
  type  = each.value.type
  value = aws_lb_listener.back[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_lb_listener.back]
}

resource "aws_ssm_parameter" "back_target_group_names" {
  for_each = local.resource_context.ssm_parameter.lb.target_group_names.back

  name  = each.value.name
  type  = each.value.type
  value = aws_lb_target_group.back[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_lb_target_group.back]
}