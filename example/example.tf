provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source                = "./../"
  name                  = "test"
  cidr_block            = "10.0.0.0/16"
  additional_cidr_block = ["172.3.0.0/16", "172.2.0.0/16"]
}