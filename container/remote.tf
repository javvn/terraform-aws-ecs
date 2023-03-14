data "terraform_remote_state" "this" {
  for_each = local.remote_path_context

  backend = "local"

  config = {
    path = each.value
  }
}