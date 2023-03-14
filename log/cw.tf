resource "aws_cloudwatch_log_group" "this" {
  for_each = local.resource_context.cw_log

  name              = each.value.cloud_watch_log_group_name
  retention_in_days = each.value.retention_in_days
  skip_destroy      = each.value.skip_destroy

  tags = merge(local.common_tags, { Name = each.value.cloud_watch_log_group_name })
}

resource "aws_ssm_parameter" "log_group_names" {
  for_each = local.ssm_parameter.log.group_names

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_cloudwatch_log_group.this[each.key].name

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.this]
}