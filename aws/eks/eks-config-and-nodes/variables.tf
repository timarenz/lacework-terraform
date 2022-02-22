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
  description = "EC2 instance type for the K8s nodes"
  type        = string
  default     = "t3.medium"
}
