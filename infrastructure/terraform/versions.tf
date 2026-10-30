terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
provider "aws" { region = var.region
  default_tags { tags = local.tags }
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" { state = "available" }
locals {
  prefix = "${var.project}-${var.environment}"
  tags = { Project = var.project, Environment = var.environment, ManagedBy = "Terraform" }
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  image_employee = "${aws_ecr_repository.employee.repository_url}:${var.employee_image_tag}"
  image_leave = "${aws_ecr_repository.leave.repository_url}:${var.leave_image_tag}"
}
