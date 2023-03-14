resource "aws_security_group" "this" {
  for_each = local.resource_context.security_groups

  vpc_id      = aws_vpc.this.id
  name        = each.key
  description = each.value.description

  tags = merge(local.common_tags, {
    Name  = each.value.name
    Usage = each.key
  })

  depends_on = [aws_vpc.this]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cidr_blocks" {
  for_each = local.resource_context.security_group_rules.cidr_blocks

  security_group_id = aws_security_group.this[each.value.key].id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks       = each.value.cidr_blocks

  depends_on = [aws_security_group.this]
}

resource "aws_security_group_rule" "source_security_groups" {
  for_each = local.resource_context.security_group_rules.source_security_groups

  security_group_id        = aws_security_group.this[each.value.key].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  description              = each.value.description
  source_security_group_id = aws_security_group.this[each.value.source_security_group_id].id

  depends_on = [aws_security_group.this]
}