output "instance" {
  value       = local.output_set.instance
  description = "The id, ami, arn, public_ip, etc.. of EC2 for bastion"
}

output "eip" {
  value       = local.output_set.eip
  description = "The public_ip, public_dns of EIP for bastion"
}