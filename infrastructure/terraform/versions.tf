terraform {

  required_version = ">= 1.6.0"
  required_providers {

    aws     = {
 source = "hashicorp/aws", version = "~> 5.80"
}
    random  = {
 source = "hashicorp/random", version = "~> 3.6"
}
    archive = {
 source = "hashicorp/archive", version = "~> 2.5"
}

}

}
provider "aws" {
 region = var.aws_region
  default_tags {
 tags = {
 Project = var.project_name, Owner = "Portfolio", Environment = "demo"
}
}

}
data "aws_caller_identity" "current" {

}
data "aws_availability_zones" "available" {
 state = "available"
}
locals {

  prefix        = var.project_name
  account_id    = data.aws_caller_identity.current.account_id
  issuer        = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
  ecr_employee  = "${aws_ecr_repository.employee.repository_url}:${var.image_tag}"
  ecr_leave     = "${aws_ecr_repository.leave.repository_url}:${var.image_tag}"

}
