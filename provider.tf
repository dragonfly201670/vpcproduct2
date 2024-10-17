terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      environment = "Dev"
      purpose     = "tf-engine"
    }
  }
}
