
output "name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "endpoint" {
  description = "EKS cluster API endpoint."
  value       = aws_eks_cluster.main.endpoint
}

output "ca_cert" {
  description = "EKS cluster CA certificate."
  sensitive   = true
  value       = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
}

output "kubeconfig" {
  description = "Kubeconfig in YAML format."
  sensitive   = true
  value       = local.kubeconfig
}

output "private_subnet_ids" {
  description = "Ids for the private subnets used by the EKS cluster."
  value       = module.environment.private_subnet_ids
}
