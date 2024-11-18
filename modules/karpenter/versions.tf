terraform {
  required_version = ">= 1.4"

  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      source  = "hashicorp/aws"
      version = "<= 5.75"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1"
    }
  }
}
