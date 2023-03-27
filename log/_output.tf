output "s3" {
  value       = local.output_set.s3
  description = "The  arn, bucket, etc.. of S3"
}

output "cw_log" {
  value       = local.output_set.cw_log
  description = "The id, arn, name, etc.. of CloudWatch Logs"
}