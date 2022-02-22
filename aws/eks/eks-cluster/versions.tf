terraform {
  required_version = "~> 1.1"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 2.1"
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
