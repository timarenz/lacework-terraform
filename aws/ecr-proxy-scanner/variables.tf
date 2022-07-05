variable "environment_name" {
  description = "Used as value of environment tag to identified resources in AWS."
  type        = string
  default     = "ecr"
}

variable "owner_name" {
  description = "Used as value of owner tag to identified resources in AWS."
  type        = string
}

variable "aws_region" {
  description = "AWS region where you want to deploy."
  type        = string
  default     = "eu-central-1"
}

variable "lacework_account_name" {
  description = "Name of your Lacework account. Used for the proxy scanner integration."
  type        = string
}

variable "lacework_integration_access_token" {
  description = "Lacework integration access token used for the proxy scanner integration. The integration has to be created within your Lacework account as type \"proxy-scanner\"."
  type        = string
  sensitive   = true
}

variable "lacework_proxy_scanner_image" {
  type    = string
  default = "lacework/lacework-proxy-scanner:latest"
}
