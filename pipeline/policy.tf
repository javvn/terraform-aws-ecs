resource "aws_iam_role" "this" {
  for_each = local.resource_context.role

  name               = each.value.name
  description        = each.value.description
  assume_role_policy = jsonencode(each.value.assume_role_policy)

  inline_policy {
    name   = local.resource_context.policy[each.key].name
    policy = jsonencode(local.resource_context.policy[each.key].statements)
  }

  tags = merge(local.common_tags, { Name = each.value.name })
}
