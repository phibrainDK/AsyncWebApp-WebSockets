locals {
  company             = "wds-ws"
  prefix              = "app-${local.company}-tf-${terraform.workspace}"
  prefix_auth         = "auth-${local.company}-tf-${terraform.workspace}"
  stage               = split("-", terraform.workspace)[0]
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "${local.prefix}-python-lambda-container"
  ecr_image_ws_tag    = "ws_latest"
  ecr_image_auth_tag  = "auth_latest"
  cooldown            = 20
  tags = {
    Example    = local.prefix
    GithubRepo = "terraform-aws-${local.company}-vpc"
    GithubOrg  = "terraform-aws-${local.company}-modules"
  }
}