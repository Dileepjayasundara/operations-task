resource "aws_vpc" "aws-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.app_environment
  }
}