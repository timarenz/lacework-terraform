
output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = data.aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_cert" {
  description = "EKS cluster CA certificate."
  sensitive   = true
  value       = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
}

output "kubeconfig" {
  description = "Kubeconfig in YAML format."
  sensitive   = true
  value       = local.kubeconfig
}
