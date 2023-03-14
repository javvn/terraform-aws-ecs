resource "aws_s3_bucket" "this" {
  bucket        = local.resource_context.s3.bucket
  force_destroy = local.resource_context.s3.force_destroy
  tags          = merge(local.common_tags, { Name = local.resource_context.s3.bucket })
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = local.resource_context.s3.public_access_block.block_public_acls
  block_public_policy     = local.resource_context.s3.public_access_block.block_public_policy
  ignore_public_acls      = local.resource_context.s3.public_access_block.ignore_public_acls
  restrict_public_buckets = local.resource_context.s3.public_access_block.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(local.resource_context.s3.policy)
}

resource "aws_ssm_parameter" "s3" {
  for_each = local.resource_context.ssm_parameter.s3

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_s3_bucket.this[each.key]

  tags = local.common_tags

  depends_on = [aws_s3_bucket.this]
}