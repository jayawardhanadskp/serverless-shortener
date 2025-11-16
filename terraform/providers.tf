terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
        }
        random = {
        source  = "hashicorp/random"
        version = "~> 3.0"
        }
    }

    backend "s3" {
      bucket = "kasun-terraform-state"
      key = "serverless-shortener.tfstate"
      region = "us-east-1"
      dynamodb_table = "terraform-locks"
    }
}

provider "aws" {
    region = var.aws_region
}