terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      # Hardcoded due to bug in K8s provider that prevents update/destroy operations due to auth errors.
      version = "2.5.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "0.12.2"
    }
  }
}
