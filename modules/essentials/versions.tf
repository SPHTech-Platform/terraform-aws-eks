terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.33"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}
