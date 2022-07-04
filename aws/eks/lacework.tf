provider "lacework" {}

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

resource "kubernetes_namespace" "lacework" {
  metadata {
    name = "lacework"
  }
}

resource "helm_release" "lacework_agent" {
  name       = "lacework-agent"
  repository = "https://lacework.github.io/helm-charts"
  chart      = "lacework-agent"
  #   version    = "5.5.0"

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
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "laceworkConfig.serverUrl"
    value = var.lacework_agent_server_url
  }

}

# module "aws_eks_audit_log" {
#   source               = "lacework/eks-audit-log/aws"
#   version              = "~> 0.2"
#   bucket_force_destroy = true
#   integration_name     = "aws-eks-${data.aws_caller_identity.current.account_id}-${random_id.id.hex}"
#   cloudwatch_regions   = [var.aws_region]
#   cluster_names        = [aws_eks_cluster.main.name]
#   prefix               = lower("lw-eks-al-${var.environment_name}-${random_id.id.hex}")
# }

module "ca" {
  source            = "git::https://github.com/timarenz/terraform-tls-root-ca.git?ref=v0.2.1"
  organization_name = var.environment_name
  common_name       = "LaceworkAdmissionCA"
}

module "admission_controller_cert" {
  # source            = "git::https://github.com/timarenz/terraform-tls-certificate.git?ref=v0.2.1"
  source = "git::https://github.com/timarenz/terraform-tls-certificate.git"
  # ca_key_algorithm  = module.ca.key_algorithm
  ca_key            = module.ca.private_key
  ca_cert           = module.ca.cert
  organization_name = var.environment_name
  common_name       = "lacework-admission-controller"
  dns_names = [
    "lacework-admission-controller.lacework",
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
  common_name       = "lacework-proxy-scanner"
  dns_names = [
    "lacework-proxy-scanner.lacework",
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
  #   version    = "0.2.14"

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

# resource "helm_release" "lacework_admission_controller" {
#   name       = "lacework-admission-controller"
#   repository = "https://lacework.github.io/helm-charts"
#   chart      = "admission-controller"
#   #   version    = "0.1.8"

#   namespace = kubernetes_namespace.lacework.metadata[0].name

#   set {
#     name  = "scanner.skipVerify"
#     value = false
#   }

#   set {
#     name  = "scanner.caCert"
#     value = base64encode(module.ca.cert)
#   }

#   set {
#     name  = "certs.serverCertificate"
#     value = base64encode(module.admission_controller_cert.cert)
#   }

#   set_sensitive {
#     name  = "certs.serverKey"
#     value = base64encode(module.admission_controller_cert.private_key)
#   }

#   set {
#     name  = "webhooks.caBundle"
#     value = base64encode(module.ca.cert)
#   }

#   set {
#     name  = "proxy-scanner.enabled"
#     value = false
#   }
# }

resource "kubernetes_secret" "container_auto_scan" {
  metadata {
    name      = "container-auto-scan"
    namespace = kubernetes_namespace.lacework.metadata[0].name
  }

  data = {
    lw_account    = var.lacework_account_name
    lw_subaccount = var.lacework_subaccount_name
    lw_api_key    = var.lacework_api_key
    lw_api_secret = var.lacework_api_secret
  }
}

resource "kubernetes_deployment" "container_auto_scan" {
  wait_for_rollout = false

  metadata {
    name      = "container-auto-scan"
    namespace = kubernetes_namespace.lacework.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "container-auto-scan"
      }
    }

    template {
      metadata {
        labels = {
          app = "container-auto-scan"
        }
      }

      spec {
        container {
          image = "alannix/container-auto-scan:main"
          # image = "alannix/container-auto-scan:latest"
          name = "container-auto-scan"
          args = ["-d", "--proxy-scanner", "https://lacework-proxy-scanner.lacework:8080", "--proxy-scanner-skip-validation"]

          env {
            name = "LW_ACCOUNT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.container_auto_scan.metadata[0].name
                key  = "lw_account"
              }
            }
          }

          env {
            name = "LW_SUBACCOUNT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.container_auto_scan.metadata[0].name
                key  = "lw_subaccount"
              }
            }
          }

          env {
            name = "LW_API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.container_auto_scan.metadata[0].name
                key  = "lw_api_key"
              }
            }
          }

          env {
            name = "LW_API_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.container_auto_scan.metadata[0].name
                key  = "lw_api_secret"
              }
            }
          }
        }
      }
    }
  }
}
