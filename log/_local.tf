locals {
  context       = yamldecode(file(var.config_file)).context
  log_context   = yamldecode(templatefile(var.config_file, local.context)).log
  ssm_parameter = yamldecode(templatefile(var.config_file, local.context)).ssm_parameter

  common_tags = {
    Env       = local.context.env
    Owner     = local.context.owner
    Project   = local.context.project
    Terraform = local.context.terraform
  }

  resource_context = {
    s3            = local.log_context.s3
    cw_log        = local.log_context.cw_log
    ssm_parameter = local.ssm_parameter
  }

  search_set = {
    s3     = ["arn", "bucket", "bucket_domain_name", "hosted_zone_id", "region", "policy", "id", "acl", "lifecycle_rule", "logging"]
    cw_log = ["arn", "id", "name", "kms_key_id", "retention_in_days"]
  }

  output_set = {
    s3     = { for k, v in aws_s3_bucket.this : k => v if contains(local.search_set.s3, k) }
    cw_log = { for r_k, r_v in aws_cloudwatch_log_group.this : r_k => { for c_k, c_v in r_v : c_k => c_v if contains(local.search_set.cw_log, c_k) } }
  }

}