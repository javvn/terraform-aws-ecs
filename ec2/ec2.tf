data "aws_ami" "this" {
  for_each = local.resource_context.ami

  most_recent = each.value.most_recent

  dynamic "filter" {
    for_each = each.value.filter

    content {
      name   = filter.key
      values = filter.value.values
    }
  }
}

resource "aws_instance" "this" {
  for_each = local.resource_context.instance

  ami = data.aws_ami.this[each.key].image_id

  key_name      = each.value.key_name
  monitoring    = each.value.monitoring
  instance_type = each.value.instance_type
  user_data     = file("${path.module}/${each.value.user_data}")

  subnet_id              = local.remote_state.network.subnet_groups[each.value.subnet_name].ids[0]
  vpc_security_group_ids = [for k, v in each.value.security_group_names : local.remote_state.network.security_groups[v].id]

  #  iam_instance_profile = aws_iam_instance_profile.ec2.name

  tags = merge(local.common_tags, { Name = each.value.name })

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "aws_eip" "this" {
  for_each = local.resource_context.eip

  vpc      = each.value.vpc
  instance = aws_instance.this[each.key].id

  tags = merge(local.common_tags, { Name = aws_instance.this[each.key].tags.Name })

  depends_on = [
    aws_instance.this
  ]
}

resource "null_resource" "bastion" {
  triggers = {
    eip_public_ip = aws_eip.this["bastion"].public_ip
  }

  provisioner "local-exec" {
    command = "if [ -z \"$(ssh-keygen -F ${aws_eip.this["bastion"].public_ip})\" ]; then  ssh-keyscan -H ${aws_eip.this["bastion"].public_ip} >> ~/.ssh/known_hosts; fi"
  }
}