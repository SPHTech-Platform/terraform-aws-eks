terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1"
    }
    # tflint-ignore: terraform_unused_required_providers
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.0"
    }
  }
}
