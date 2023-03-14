resource "aws_vpc" "this" {
  cidr_block           = local.resource_context.vpc.cidr_block
  instance_tenancy     = local.resource_context.vpc.instance_tenancy
  enable_dns_hostnames = local.resource_context.vpc.enable_dns_hostnames
  tags                 = local.resource_context.vpc.tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = local.resource_context.igw.tags

  depends_on = [aws_vpc.this]
}

resource "aws_subnet" "ingress" {
  count = length(local.resource_context.subnet_groups.ingress)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.resource_context.subnet_groups.ingress[count.index].cidr_block
  availability_zone_id    = local.resource_context.subnet_groups.ingress[count.index].availability_zone_id
  map_public_ip_on_launch = local.resource_context.subnet_groups.ingress[count.index].map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name  = local.resource_context.subnet_groups.ingress[count.index].name
    Usage = "ingress"
  })

  depends_on = [aws_vpc.this]
}

resource "aws_subnet" "management" {
  count = length(local.resource_context.subnet_groups.management)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.resource_context.subnet_groups.management[count.index].cidr_block
  availability_zone_id    = local.resource_context.subnet_groups.management[count.index].availability_zone_id
  map_public_ip_on_launch = local.resource_context.subnet_groups.management[count.index].map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name  = local.resource_context.subnet_groups.management[count.index].name
    Usage = "management"
  })

  depends_on = [aws_vpc.this]
}

resource "aws_subnet" "container" {
  count = length(local.resource_context.subnet_groups.container)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.resource_context.subnet_groups.container[count.index].cidr_block
  availability_zone_id    = local.resource_context.subnet_groups.container[count.index].availability_zone_id
  map_public_ip_on_launch = local.resource_context.subnet_groups.container[count.index].map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name  = local.resource_context.subnet_groups.container[count.index].name
    Usage = "container"
  })

  depends_on = [aws_vpc.this]
}

resource "aws_subnet" "vpce" {
  count = length(local.resource_context.subnet_groups.vpce)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.resource_context.subnet_groups.vpce[count.index].cidr_block
  availability_zone_id    = local.resource_context.subnet_groups.vpce[count.index].availability_zone_id
  map_public_ip_on_launch = local.resource_context.subnet_groups.vpce[count.index].map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name  = local.resource_context.subnet_groups.vpce[count.index].name
    Usage = "vpce"
  })

  depends_on = [aws_vpc.this]
}

resource "aws_subnet" "db" {
  count = length(local.resource_context.subnet_groups.db)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.resource_context.subnet_groups.db[count.index].cidr_block
  availability_zone_id    = local.resource_context.subnet_groups.db[count.index].availability_zone_id
  map_public_ip_on_launch = local.resource_context.subnet_groups.db[count.index].map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name  = local.resource_context.subnet_groups.db[count.index].name
    Usage = "db"
  })

  depends_on = [aws_vpc.this]
}

resource "aws_route_table" "this" {
  for_each = local.resource_context.route_table

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = each.value.route

    content {
      cidr_block = route.value.cidr_block
      gateway_id = aws_internet_gateway.this.id
    }
  }

  tags = merge(local.common_tags, {
    Name  = each.value.name
    Usage = each.key
  })

  depends_on = [aws_vpc.this, aws_internet_gateway.this]
}

resource "aws_route_table_association" "ingress" {
  count = length(concat(aws_subnet.ingress[*].id, aws_subnet.management[*].id))

  subnet_id      = element(concat(aws_subnet.ingress[*].id, aws_subnet.management[*].id), count.index)
  route_table_id = aws_route_table.this["ingress"].id

  depends_on = [
    aws_subnet.ingress,
    aws_subnet.management,
    aws_route_table.this
  ]
}

resource "aws_route_table_association" "container" {
  count = length(aws_subnet.container[*].id)

  subnet_id      = element(aws_subnet.container[*].id, count.index)
  route_table_id = aws_route_table.this["container"].id

  depends_on = [
    aws_subnet.container,
    aws_route_table.this
  ]
}

resource "aws_route_table_association" "db" {
  count = length(aws_subnet.db[*].id)

  subnet_id      = element(aws_subnet.db[*].id, count.index)
  route_table_id = aws_route_table.this["db"].id

  depends_on = [
    aws_subnet.db,
    aws_route_table.this
  ]
}

resource "aws_vpc_endpoint" "this" {
  count = local.resource_context.vpc_endpoint.create ? length(local.resource_context.vpc_endpoint.endpoints) : 0

  vpc_id              = aws_vpc.this.id
  service_name        = local.resource_context.vpc_endpoint.endpoints[count.index].service_name
  vpc_endpoint_type   = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type
  ip_address_type     = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type == "Interface" ? local.resource_context.vpc_endpoint.endpoints[count.index].ip_address_type : null
  private_dns_enabled = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type == "Interface" ? true : null

  subnet_ids         = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type == "Interface" ? aws_subnet.vpce[*].id : null
  security_group_ids = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type == "Interface" ? [aws_security_group.this["vpce"].id] : null
  route_table_ids    = local.resource_context.vpc_endpoint.endpoints[count.index].vpc_endpoint_type == "Interface" ? null : [aws_route_table.this["container"].id]

  depends_on = [
    aws_vpc.this,
    aws_subnet.vpce,
    aws_route_table.this,
    aws_security_group.this
  ]
}

