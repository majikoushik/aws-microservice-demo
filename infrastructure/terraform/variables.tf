variable "aws_region" {
 type = string
 default = "ap-south-1"
}
variable "project_name" {

  type = string
  default = "workforce-demo"
  validation {

    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project_name))
    error_message = "Use 3-20 lowercase letters, digits and hyphens, starting with a letter."

}

}
variable "image_tag" {
 type = string
 default = "v1"
}
variable "db_instance_class" {
 type = string
 default = "db.t4g.micro"
}
variable "budget_email" {
 type = string
 description = "Email to notify about AWS spending."
}
variable "monthly_budget_usd" {
 type = string
 default = "20"
}
variable "enable_pipeline" {
 type = bool
 default = false
}
variable "github_owner" {
 type = string
 default = ""
}
variable "github_repo" {
 type = string
 default = "workforce-management-system"
}
variable "github_branch" {
 type = string
 default = "main"
}
