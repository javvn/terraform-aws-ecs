locals {
  context               = yamldecode(file(var.config_file)).context
  container_context     = yamldecode(templatefile(var.config_file, local.context)).container
  ssm_parameter_context = yamldecode(templatefile(var.config_file, local.context)).ssm_parameter

  common_tags = {
    Env       = local.context.env
    Owner     = local.context.owner
    Project   = local.context.project
    Terraform = local.context.terraform
  }

  remote_state = { for k, v in data.terraform_remote_state.this : k => v["outputs"] }

  remote_path_context = {
    network = "${path.module}/${yamldecode(file(var.config_file)).remote_path.network}"
    log     = "${path.module}/${yamldecode(file(var.config_file)).remote_path.log}"
  }

  resource_context = {
    ecr                 = local.container_context.ecr
    ecs                 = local.container_context.ecs
    ecs_task_definition = local.container_context.ecs_task_definition
    ecs_service         = local.container_context.ecs_service
    lb = {
      L7 = { for r_k, r_v in local.container_context.lb.L7 : r_k => merge(r_v, {
        subnets         = local.remote_state.network.subnet_groups[r_v.ref_key.subnet_name].ids
        security_groups = [for c_k, c_v in r_v.ref_key.security_group_names : local.remote_state.network.security_groups[c_v].id]
      }) }
      target_group = {
        front = { for r_k, r_v in local.container_context.lb.target_group.front : r_k => merge(r_v, {
          vpc_id = local.remote_state.network.vpc.id
        }) }
        back = { for r_k, r_v in local.container_context.lb.target_group.back : r_k => merge(r_v, {
          vpc_id = local.remote_state.network.vpc.id
        }) }
      }
      listener = { for k, v in local.container_context.lb.listener : k => v }
    }
    ssm_parameter = {
      ecr = local.ssm_parameter_context.ecr
      ecs = local.ssm_parameter_context.ecs
      lb  = local.ssm_parameter_context.lb
    }
  }

  search_set = {
    ecr = {
      private = [
        "id",
        "arn",
        "name",
        "registry_id",
        "repository_url",
      ]
      public = [
        "id",
        "arn",
        "registry_id",
        "repository_uri",
      ]
    }
    ecs = {
      cluster = [
        "id",
        "arn",
        "name",
        "setting",
        "configuration",
      ]
      capacity_providers = [
        "capacity_providers",
        "default_capacity_provider_strategy"
      ]
      task_definition = [
        "id",
        "arn",
        "cpu",
        "family",
        "memory",
        "runtime_platform",
        "container_definitions",
        "requires_compatibilities",
      ]
      service = [
        "id",
        "arn",
        "name",
        "iam_role",
        "launch_type",
        "load_balancer",
        "task_definition",
        "network_configuration",
      ]
    }
    lb = {
      L7 = [
        "id",
        "arn",
        "name",
        "vpc_id",
        "subnets",
        "dns_name",
        "internal",
        "access_logs",
        "security_groups",
        "ip_address_type",
        "load_balancer_type",
      ]
      target_group = [
        "id",
        "arn",
        "name",
        "port",
        "vpc_id",
      ]
      listener = [
        "id",
        "arn",
        "port",
        "load_balancer_arn",
      ]
    }
  }

  output_set = {
    ecr = {
      private = { for r_k, r_v in aws_ecr_repository.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.ecr.private, c_k) } }
      public  = { for r_k, r_v in aws_ecrpublic_repository.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.ecr.public, c_k) } }
    }
    ecs = {
      cluster = { for r_k, r_v in aws_ecs_cluster.this : r_k => merge(
        { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.ecs.cluster, c_k) },
        { for k, v in aws_ecs_cluster_capacity_providers.this[r_k] : k => v if contains(local.search_set.ecs
        .capacity_providers, k) }
      ) }
      task_definition = { for r_k, r_v in aws_ecs_task_definition.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.ecs.task_definition, c_k) } }
      service         = { for r_k, r_v in aws_ecs_service.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.ecs.service, c_k) } }
    }
    lb = {
      L7 = { for r_k, r_v in aws_lb.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.lb.L7, c_k) } }
      target_group = {
        front = { for r_k, r_v in aws_lb_target_group.front : r_k => { for c_k, c_v in r_v : c_k => c_v if contains
        (local.search_set.lb.target_group, c_k) } }
        back = { for r_k, r_v in aws_lb_target_group.back : r_k => { for c_k, c_v in r_v : c_k => c_v if contains
        (local.search_set.lb.target_group, c_k) } }
      }
      listener = {
        front = { for r_k, r_v in aws_lb_listener.front : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local
        .search_set.lb.listener, c_k) } }
        back = { for r_k, r_v in aws_lb_listener.back : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local
        .search_set.lb.listener, c_k) } }
      }
    }
  }
}
