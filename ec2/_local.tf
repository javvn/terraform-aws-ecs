locals {
  context     = yamldecode(file(var.config_file)).context
  ec2_context = yamldecode(templatefile(var.config_file, local.context)).ec2
  remote_path_context = {
    network   = "${path.module}/${yamldecode(file(var.config_file)).remote_path.network}"
    log       = "${path.module}/${yamldecode(file(var.config_file)).remote_path.log}"
    container = "${path.module}/${yamldecode(file(var.config_file)).remote_path.container}"
  }
  remote_state = { for k, v in data.terraform_remote_state.this : k => v["outputs"] }

  common_tags = {
    Env       = local.context.env
    Owner     = local.context.owner
    Project   = local.context.project
    Terraform = local.context.terraform
  }

  resource_context = {
    ami            = local.ec2_context.ami
    eip            = local.ec2_context.eip
    instance       = local.ec2_context.instance
    instance_state = local.ec2_context.state
  }

  search_set = {
    instance = [
      "id",
      "ami",
      "arn",
      "subnet_id",
      "public_ip",
      "public_dns",
      "instance_type",
      "instance_state",
      "vpc_security_group_ids",
    ]
    eip = [
      "public_ip",
      "public_dns",
    ]
  }

  output_set = {
    instance = { for r_k, r_v in aws_instance.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.instance, c_k) } }
    eip      = { for r_k, r_v in aws_eip.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.eip, c_k) } }
  }
}