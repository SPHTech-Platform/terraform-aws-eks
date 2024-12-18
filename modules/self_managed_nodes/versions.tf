terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12"
    }
  }
}
