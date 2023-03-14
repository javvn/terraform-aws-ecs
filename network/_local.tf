locals {
  context         = yamldecode(file(var.config_file)).context
  network_context = yamldecode(templatefile(var.config_file, local.context)).network

  common_tags = {
    Env       = local.context.env
    Owner     = local.context.owner
    Project   = local.context.project
    Terraform = local.context.terraform
  }

  resource_context = {
    vpc             = merge(local.network_context.vpc, { tags = merge(local.common_tags, { Name = local.network_context.vpc.name }) })
    igw             = merge(local.network_context.igw, { tags = merge(local.common_tags, { Name = local.network_context.igw.name }) })
    subnet_groups   = local.network_context.subnet_groups
    route_table     = local.network_context.route_table
    security_groups = local.network_context.security_groups
    security_group_rules = {
      cidr_blocks            = { for k, v in local.network_context.security_group_rules : k => v if v.ref == "cidr_blocks" }
      source_security_groups = { for k, v in local.network_context.security_group_rules : k => v if v.ref == "source_security_group_id" }
    }
    vpc_endpoint = local.network_context.vpc_endpoint
  }

  search_set = {
    vpc            = ["arn", "cidr_block", "enable_network_address_usage_metrics", "id"]
    igw            = ["arn", "id", "vpc_id"]
    route_table    = ["id"]
    security_group = ["arn", "id", "description", "name"]
  }

  output_set = {
    vpc = { for k, v in aws_vpc.this : k => v if contains(local.search_set.vpc, k) }
    igw = { for k, v in aws_internet_gateway.this : k => v if contains(local.search_set.igw, k) }
    subnet_groups = {
      ingress = {
        names       = aws_subnet.ingress[*].tags.Name
        arns        = aws_subnet.ingress[*].arn
        ids         = aws_subnet.ingress[*].id
        cidr_blocks = aws_subnet.ingress[*].cidr_block
      }
      management = {
        names       = aws_subnet.management[*].tags.Name
        arns        = aws_subnet.management[*].arn
        ids         = aws_subnet.management[*].id
        cidr_blocks = aws_subnet.management[*].cidr_block
      }
      container = {
        names       = aws_subnet.container[*].tags.Name
        arns        = aws_subnet.container[*].arn
        ids         = aws_subnet.container[*].id
        cidr_blocks = aws_subnet.container[*].cidr_block
      }
      vpce = {
        names       = aws_subnet.vpce[*].tags.Name
        arns        = aws_subnet.vpce[*].arn
        ids         = aws_subnet.vpce[*].id
        cidr_blocks = aws_subnet.vpce[*].cidr_block
      }
      db = {
        names       = aws_subnet.db[*].tags.Name
        arns        = aws_subnet.db[*].arn
        ids         = aws_subnet.db[*].id
        cidr_blocks = aws_subnet.db[*].cidr_block
      }
    }
    route_table     = { for r_k, r_v in aws_route_table.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.route_table, c_k) } }
    security_groups = { for r_k, r_v in aws_security_group.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.security_group, c_k) } }
    vpc_endpoint    = aws_vpc_endpoint.this[*].service_name
  }

}