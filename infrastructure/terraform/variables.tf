variable "project" { type = string; default = "workforce" }
variable "environment" { type = string
  validation { condition = contains(["dev", "staging", "prod"], var.environment); error_message = "Use dev, staging or prod." }
}
variable "region" { type = string; default = "us-east-2" }
variable "vpc_cidr" { type = string; default = "10.30.0.0/16" }
variable "db_username" { type = string; default = "admin" }
variable "db_password" { type = string; sensitive = true
  validation { condition = length(var.db_password) >= 12; error_message = "Supply a DB password at least 12 characters long." }
}
variable "db_instance_class" { type = string; default = "db.t4g.micro" }
variable "db_allocated_storage" { type = number; default = 20 }
variable "db_multi_az" { type = bool; default = false }
variable "deletion_protection" { type = bool; default = false }
variable "enable_services" { type = bool; default = false; description = "Enable only after pushing both images to ECR." }
variable "employee_image_tag" { type = string; default = "latest" }
variable "leave_image_tag" { type = string; default = "latest" }
variable "ecs_cpu" { type = number; default = 512 }
variable "ecs_memory" { type = number; default = 1024 }
variable "ecs_desired_count" { type = number; default = 1 }
variable "cognito_domain_prefix" { type = string; default = ""; description = "Optional custom globally unique Cognito prefix; empty derives from account/region/environment." }
variable "postman_callback_url" { type = string; default = "https://oauth.pstmn.io/v1/callback" }
variable "github_repo_url" { type = string; default = ""; description = "Example: https://github.com/ORG/REPO . Empty disables CodeBuild." }
variable "codebuild_connection_arn" { type = string; default = ""; description = "Pre-authorized AWS CodeConnections ARN for GitHub." }
variable "github_source_version" { type = string; default = "main" }
variable "private_ecs_with_nat" { type = bool; default = false; description = "Production-oriented: place ECS tasks in private subnets and provision one NAT gateway (costs extra)." }
