terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
  }

  required_version = ">= 1.3.0"

  backend "local" {
    path = "terraform.tfstate"
    
  }
}
provider "aws" {
  region = var.region
  
}