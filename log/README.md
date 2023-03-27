# log

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.3.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_ssm_parameter.log_group_names](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_file"></a> [config\_file](#input\_config\_file) | The configuration for CloudWatch, S3 | `string` | `"../config.yaml"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cw_log"></a> [cw\_log](#output\_cw\_log) | The id, arn, name, etc.. of CloudWatch Logs |
| <a name="output_s3"></a> [s3](#output\_s3) | The  arn, bucket, etc.. of S3 |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
