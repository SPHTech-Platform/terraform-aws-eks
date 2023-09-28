terraform {
  required_version = ">= 1.4"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}
