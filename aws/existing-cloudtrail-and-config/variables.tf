variable "environment_name" {
  description = "Used as value of environment tag to identified resources in AWS."
  type        = string
}

variable "owner_name" {
  description = "Used as value of owner tag to identified resources in AWS."
  type        = string
}

variable "aws_default_region" {
  description = "Default region used if not specified otherwise."
  type        = string
  default     = "eu-central-1"
}

variable "existing_s3_bucket" {
  description = "Name of the existing S3 bucket used by CloudTrail."
  type        = string
}
