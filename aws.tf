provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
  version    = "~> 2.70.0"
}

resource "aws_vpc" "this" {
  cidr_block                       = var.aws_vpc_cidr
  assign_generated_ipv6_cidr_block = false
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    "Name"    = var.skg_name
    "usecase" = "secure-k8s-gateway"
  }
}

resource "aws_subnet" "this" {
  for_each          = var.aws_subnet_cidr
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.aws_az
  tags = {
    "Name"        = format("%s-%s", var.skg_name, each.key)
    "usecase"     = "secure-k8s-gateway"
    "subnet-type" = each.key
  }
}

