resource "aws_codecommit_repository" "this" {
  for_each = local.resource_context.repository

  repository_name = each.value.name
  description     = each.value.description
  default_branch  = each.value.default_branch

  tags = merge(local.common_tags, { Name = each.value.name })

  lifecycle {
    ignore_changes = [
      default_branch
    ]
  }
}