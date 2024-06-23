terraform {
  backend "s3" {
    bucket         = "terraform.state.mickovich.com"
    key            = "aws-services1.tfstate"
    dynamodb_table = "terraform-locks"
    region         = "us-east-2"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region="us-east-2"
  assume_role {
    role_arn = var.assume_role
  }
  default_tags {
    tags = {
      Service = var.service
      Stage   = terraform.workspace
    }
  }
}
