resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role-${random_id.id.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "main" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  name                      = "eks-cluster-${random_id.id.hex}"
  version                   = "1.21"
  role_arn                  = aws_iam_role.eks_cluster.arn
  enabled_cluster_log_types = ["audit", "authenticator"]

  vpc_config {
    subnet_ids             = module.environment.private_subnet_ids
    endpoint_public_access = true
    # Restrict access to the public IP address of the machine used to deploy this and also the NAT gateway of the environment to allow the EKS nodes to join.
    public_access_cidrs = [
      "${lookup(jsondecode(data.http.current_ip.body), "ip")}/32",
      "${module.environment.nat_gateway_public_ip}/32"
    ]
  }

  tags = {
    "environment" = var.environment_name
    "owner"       = var.owner_name
  }
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
    aws_iam_role_policy_attachment.eks_cni,
    # aws_eks_identity_provider_config.main,
    # aws_iam_role_policy_attachment.eks_vpc_cni,
  ]

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "eks-node-group-${random_id.id.hex}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = module.environment.private_subnet_ids

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

resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "${path.root}/kubeconfig.yaml"
}
