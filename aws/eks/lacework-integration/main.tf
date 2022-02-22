data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}


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

data "lacework_agent_access_token" "eks" {
  name = var.lacework_agent_token_name
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

resource "kubernetes_namespace" "lacework" {
  metadata {
    name = "lacework"
  }
}

resource "helm_release" "lacework_agent" {
  name       = "lacework-agent"
  repository = "https://lacework.github.io/helm-charts"
  chart      = "lacework-agent"
  version    = "5.2.0"

  namespace = kubernetes_namespace.lacework.metadata[0].name

  set {
    name  = "laceworkConfig.autoUpgrade"
    value = "disable"
  }

  set_sensitive {
    name  = "laceworkConfig.accessToken"
    value = data.lacework_agent_access_token.eks.token
  }

  set {
    name  = "laceworkConfig.env"
    value = "k8s"
  }

  set {
    name  = "laceworkConfig.kubernetesCluster"
    value = data.terraform_remote_state.cluster.outputs.name
  }

  set {
    name  = "laceworkConfig.serverUrl"
    value = var.lacework_agent_server_url
  }

}

module "ca" {
  source            = "git::https://github.com/timarenz/terraform-tls-root-ca.git?ref=v0.2.1"
  organization_name = var.environment_name
  common_name       = "LaceworkAdmissionCA"
}

module "admission_controller_cert" {
  source            = "git::https://github.com/timarenz/terraform-tls-certificate.git?ref=v0.2.1"
  ca_key_algorithm  = module.ca.key_algorithm
  ca_key            = module.ca.private_key
  ca_cert           = module.ca.cert
  organization_name = var.environment_name
  common_name       = "lacework-admission-controller.lacework"
  dns_names = [
    "lacework-admission-controller.lacework.svc",
    "lacework-admission-controller.lacework.svc.cluster.local"
  ]
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "content_commitment" #nonRepudiation
  ]
}

module "proxy_scanner_cert" {
  source            = "git::https://github.com/timarenz/terraform-tls-certificate.git?ref=v0.2.1"
  ca_key_algorithm  = module.ca.key_algorithm
  ca_key            = module.ca.private_key
  ca_cert           = module.ca.cert
  organization_name = var.environment_name
  common_name       = "lacework-proxy-scanner.lacework"
  dns_names = [
    "lacework-proxy-scanner.lacework.svc",
    "lacework-proxy-scanner.lacework.svc.cluster.local"
  ]
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "content_commitment" #nonRepudiation
  ]
}

resource "helm_release" "lacework_proxy_scanner" {
  name       = "lacework-proxy-scanner"
  repository = "https://lacework.github.io/helm-charts"
  chart      = "proxy-scanner"
  version    = "0.2.9"

  namespace = kubernetes_namespace.lacework.metadata[0].name

  values = [var.lacework_proxy_scanner_config]

  set {
    name  = "config.lacework.account_name"
    value = var.lacework_account_name
  }

  set_sensitive {
    name  = "config.lacework.integration_access_token"
    value = var.lacework_integration_access_token
  }

  set {
    name  = "certs.skipCert"
    value = false
  }

  set {
    name  = "certs.serverCertificate"
    value = base64encode(module.proxy_scanner_cert.cert)
  }

  set_sensitive {
    name  = "certs.serverKey"
    value = base64encode(module.proxy_scanner_cert.private_key)
  }
}


resource "helm_release" "lacework_admission_controller" {
  name       = "lacework-admission-controller"
  repository = "https://lacework.github.io/helm-charts"
  chart      = "admission-controller"
  version    = "0.1.6"

  namespace = kubernetes_namespace.lacework.metadata[0].name

  set {
    name  = "scanner.skipVerify"
    value = true
  }

  set {
    name  = "scanner.caCert"
    value = base64encode(module.ca.cert)
  }

  set {
    name  = "certs.serverCertificate"
    value = base64encode(module.admission_controller_cert.cert)
  }

  set_sensitive {
    name  = "certs.serverKey"
    value = base64encode(module.admission_controller_cert.private_key)
  }

  set {
    name  = "webhooks.caBundle"
    value = base64encode(module.ca.cert)
  }

  set {
    name  = "proxy-scanner.enabled"
    value = false
  }
}
