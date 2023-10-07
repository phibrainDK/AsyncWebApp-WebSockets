variable "tf_backend_bucket_name" {
  description = "The bucket name to store terraform backend state"
  type        = string
}

variable "tf_backend_key_name" {
  description = "The bucket key name to store terraform backend state"
  type        = string
}

variable "tf_backend_kms_key_alias_name" {
  description = "The KMS key alias name"
  type        = string
}

variable "tf_backend_dynamodb_table" {
  description = "The dynamoDB table to lock consistent writes/reads"
  type        = string
}

variable "deploy_region" {
  description = "The AWS region to deploy resources to"
  type        = string
}