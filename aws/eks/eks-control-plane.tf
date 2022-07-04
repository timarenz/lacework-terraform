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
