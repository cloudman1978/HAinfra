terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for eu-west-3 (Paris)
provider "aws" {
  alias  = "paris"
  region = "eu-west-3"

  default_tags {
    tags = {
      createdby = "asa"
    }
  }
}

# Provider for eu-west-1 (Ireland)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"

    default_tags {
    tags = {
      createdby = "asa"
    }
  }
}
