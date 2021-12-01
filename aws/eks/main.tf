provider "aws" {
  region = var.aws_region
}

provider "lacework" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

locals {
  kubeconfig = templatefile("${path.module}/templates/kubeconfig.yaml.tpl", {
    endpoint-url           = aws_eks_cluster.main.endpoint
    base64-encoded-ca-cert = aws_eks_cluster.main.certificate_authority[0].data
    cluster-name           = aws_eks_cluster.main.name
  })
}

data "aws_caller_identity" "current" {}

data "lacework_agent_access_token" "eks" {
  name = var.lacework_agent_token_name
}

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

data "http" "current_ip" {
  # url = "https://api.ipify.org/?format=json"
  url = "https://api4.my-ip.io/ip.json"
}

resource "random_id" "id" {
  byte_length = 3
}

module "environment" {
  # source           = "timarenz/environment/aws"
  source           = "git::https://github.com/timarenz/terraform-aws-environment.git"
  name             = "${var.environment_name}-${random_id.id.hex}"
  environment_name = var.environment_name
  owner_name       = var.owner_name
  public_subnets = [
    {
      "name" : "public-subnet-0",
      "prefix" : "192.168.30.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
      }, {
      "name" : "public-subnet-1",
      "prefix" : "192.168.31.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
      }, {
      "name" : "public-subnet-2",
      "prefix" : "192.168.32.0/24",
      "tags" : {
        "kubernetes.io/role/elb" : "1"
      }
    }
  ]
  private_subnets = [
    { "name" : "private-subnet-0",
      "prefix" : "192.168.40.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
      }, {
      "name" : "private-subnet-1",
      "prefix" : "192.168.41.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
      }, {
      "name" : "private-subnet-2",
      "prefix" : "192.168.42.0/24",
      "tags" : {
        "kubernetes.io/role/internal-elb" : "1"
      }
    }
  ]
}
