terraform {
  required_version = "~> 1.1"
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}
