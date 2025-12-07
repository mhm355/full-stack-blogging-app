terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "devops-projects-state-files"
    key    = "devops-projects-state-files/fullstack-blogging-app/dev-env/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
