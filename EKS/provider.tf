terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">=6.0.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    helm = {
    source = "hashicorp/helm"
    version = "3.1.0"
    }

  }
}

provider "aws" {
  region = "us-east-1"  
}

provider "kubernetes" {
    config_path    = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}