# terraform {
#   backend "s3" {

#   }
# }

provider "aws" {
  region = var.deploy_region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

