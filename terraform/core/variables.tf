variable "deploy_region" {
  description = "The AWS region to deploy resources to"
  type        = string
}

variable "backend_bucket_name" {
  description = "The S3 AWS bucket for backend files"
  type        = string
}

variable "api_url_prefix" {
  description = "The API url preffix"
  type        = string
}


variable "api_version" {
  description = "The API version"
  type        = string
}
