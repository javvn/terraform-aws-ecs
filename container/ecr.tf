resource "aws_ecr_repository" "this" {
  for_each = local.resource_context.ecr.private

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.image_scanning_configuration.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_configuration.encryption_type
  }

  tags = merge(local.common_tags, { Name = each.value.name })
}

resource "aws_ecrpublic_repository" "this" {
  for_each = local.resource_context.ecr.public

  repository_name = each.value.repository_name

  catalog_data {
    description       = each.value.catalog_data.description
    about_text        = each.value.catalog_data.about_text
    usage_text        = each.value.catalog_data.usage_text
    logo_image_blob   = each.value.catalog_data.logo_image_blob
    architectures     = each.value.catalog_data.architectures
    operating_systems = each.value.catalog_data.operating_systems
  }

  timeouts {
    delete = each.value.timeouts.delete
  }

  tags = merge(local.common_tags, { Name = each.value.repository_name })

  #  lifecycle {
  #    prevent_destroy = true
  #  }
}

resource "aws_ssm_parameter" "ecr_repository_url" {
  for_each = local.resource_context.ssm_parameter.ecr.repository_url

  name      = each.value.name
  type      = each.value.type
  data_type = each.value.data_type
  value     = aws_ecr_repository.this[each.key][each.value.key]

  tags = local.common_tags

  depends_on = [aws_ecr_repository.this]
}

resource "null_resource" "ecr_repo_back" {
  triggers = {
    ecr_repo_url = aws_ecr_repository.this["back"].repository_url
  }

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/image-push.sh"

    environment = {
      REGION         = "us-east-1"
      REPOSITORY_URL = aws_ecr_repository.this["back"].repository_url
    }
  }
}

