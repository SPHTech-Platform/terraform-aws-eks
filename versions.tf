terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.33"
    }
    # tflint-ignore: terraform_unused_required_providers
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1"
    }
    # tflint-ignore: terraform_unused_required_providers
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
  }
}
