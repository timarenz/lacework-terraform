variable "environment_name" {
  description = "Used as value of environment tag to identified resources in AWS."
  type        = string
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

variable "k8s_admin_role" {
  description = "Map that contains the name and arn of an AWS role you want to assign the cluster-admin role in the EKS cluster. Example: `{ name = \"admin\", arn = \"rn:aws:iam::123456789012:role/eks-admin-role\" }`."
  type        = map(string)
  #   default = {
  #   name = "admin"
  #   arn  = "arn:aws:iam::123456789012:role/eks-admin-role"
  # }
}

variable "node_instance_type" {
  description = "EC2 instance type for the K8s nodes."
  type        = string
  default     = "t3.medium"
}

variable "lacework_agent_token_name" {
  description = "Name of the Lacework agent token to use to deploy the Lacework agent. This token will not be created using Terraform and there has to be preexisting in your Lacework account."
  type        = string
}

variable "lacework_agent_server_url" {
  description = "Lacework API Url the agent should connect to. By default the US region is used (`https://api.lacework.net`). If you are using the EU region, use `https://api.fra.lacework.net` as value."
  type        = string
  default     = "https://api.lacework.net"
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

variable "lacework_proxy_scanner_config" {
  description = "Lacework proxy scanner configuration. Please refere to the documentation: https://docs.lacework.com/integrate-proxy-scanner#configure-for-on-demand-scans."
  type        = string
  sensitive   = true
  # default     = <<-EOF
  #   config:
  #     static_cache_location: /opt/lacework
  #     scan_public_registries: true
  #     default_registry: index.docker.io
  #     registries:
  #       - domain: index.docker.io
  #         name: Docker Hub
  #         ssl: true
  #         is_public: true
  #         auto_poll: false
  #         disable_non_os_package_scanning: false
  #   EOF
}

variable "lacework_api_key" {
  description = "Lacework API key used by container-auto-scan."
  type        = string
}

variable "lacework_api_secret" {
  description = "Lacework API secret used by container-auto-scan."
  type        = string
  sensitive   = true
}

variable "lacework_subaccount_name" {
  description = "Lacework sub account name used by container-auto-scan."
  type        = string
  default     = null
}
