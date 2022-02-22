terraform {
  required_version = "~> 1.1"
  required_providers {
    http = {
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
  }
}
