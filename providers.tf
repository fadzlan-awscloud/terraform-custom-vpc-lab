
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Targets the stable modern 6.x release line
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Deploys directly to the Singapore region closest to you
}