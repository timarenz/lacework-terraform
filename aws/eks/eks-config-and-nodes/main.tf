data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}


provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster" "main" {
  name = data.terraform_remote_state.cluster.outputs.name
}

data "aws_eks_cluster_auth" "main" {
  name = data.terraform_remote_state.cluster.outputs.name
}

resource "random_id" "id" {
  byte_length = 3
}

resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: ${lookup(var.k8s_admin_role, "arn")}
  username: ${lookup(var.k8s_admin_role, "name")}
  groups:
    - system:masters
- rolearn: ${aws_iam_role.eks_node_group.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOF
  }
}

resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group-role-${random_id.id.hex}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_eks_node_group" "main" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_cni
  ]

  cluster_name    = data.terraform_remote_state.cluster.outputs.name
  node_group_name = "eks-node-group-${random_id.id.hex}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = data.terraform_remote_state.cluster.outputs.private_subnet_ids[*]

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    "environment" = var.environment_name
    "owner"       = var.owner_name
  }
}
