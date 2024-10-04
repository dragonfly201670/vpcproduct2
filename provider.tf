terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
  }
}

provider "aws" {
  profile = "AWSAdministratorAccess-335184790956"
  region  = "eu-west-1"
  default_tags {
    tags = {
      environment = "Dev"
      purpose     = "tf-engine"
    }
  }
}