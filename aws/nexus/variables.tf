variable "environment_name" {
  description = "Used as value of environment tag to identified resources in AWS."
  type        = string
  default     = "nexus"
}

variable "owner_name" {
  description = "Used as value of owner tag to identified resources in AWS."
  type        = string
}

variable "aws_region" {
  description = "AWS region where you want to deploy this EKS cluster."
  type        = string
  default     = "eu-central-1"
}

variable "ssh_public_key_name" {
  type = string
}

variable "lacework_account_name" {
  type = string
}

variable "lacework_integration_access_token" {
  type      = string
  sensitive = true
}

variable "lacework_proxy_scanner_image" {
  type    = string
  default = "lacework/lacework-proxy-scanner"
}

variable "route53_zone_name" {
  description = "This zone has to existing in the environment. Value needs to end with a `.`, for example, `myzone.tld.`."
  type        = string
}

variable "nexus_fqdn" {
  description = "FQDN of the Nexus repository used to set up DNS CNAME and ACM certificate. Should use the same TLD as the `route53_zone_name`."
  type        = string
}

variable "nexus_password" {
  description = "This password will be used to configure the Lacework proxy scanner. This should be the same password set during the set up of the Nexus admin account."
  type        = string
  sensitive   = true
  default     = "laceworkproxyscanner"
}

variable "nexus_disk_size" {
  description = "Disk size of the Nexus server in GiB. Defaults to 64GB, more might be required."
  type        = number
  default     = 64

}
