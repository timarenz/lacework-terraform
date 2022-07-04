locals {
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.yaml.tpl", {
    endpoint-url           = aws_eks_cluster.main.endpoint
    base64-encoded-ca-cert = aws_eks_cluster.main.certificate_authority[0].data
    cluster-name           = aws_eks_cluster.main.name
    arn                    = aws_eks_cluster.main.arn
    region                 = var.aws_region
  })
}

resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "${path.root}/kubeconfig.yaml"
}
