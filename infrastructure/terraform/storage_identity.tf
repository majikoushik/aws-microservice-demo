resource "aws_ecr_repository" "employee" {

  name = "${local.prefix}/employee"
  image_scanning_configuration {
 scan_on_push = true
}
  force_delete = true # Demo teardown; DO NOT use in production with valuable images.

}
resource "aws_ecr_repository" "leave" {

  name = "${local.prefix}/leave"
  image_scanning_configuration {
 scan_on_push = true
}
  force_delete = true

}
resource "aws_ecr_lifecycle_policy" "employee" {

  repository = aws_ecr_repository.employee.name
  policy = jsonencode({
 rules = [{
 rulePriority = 1, description = "Keep last 3 images",
    selection = {
 tagStatus = "any", countType = "imageCountMoreThan", countNumber = 3
},
    action = {
 type = "expire"
}
}]
})

}
resource "aws_ecr_lifecycle_policy" "leave" {

  repository = aws_ecr_repository.leave.name
  policy = jsonencode({
 rules = [{
 rulePriority = 1, description = "Keep last 3 images",
    selection = {
 tagStatus = "any", countType = "imageCountMoreThan", countNumber = 3
},
    action = {
 type = "expire"
}
}]
})

}
resource "aws_s3_bucket" "documents" {
 bucket_prefix = "${local.prefix}-docs-"
 force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "documents" {

  bucket = aws_s3_bucket.documents.id
  block_public_acls = true
 block_public_policy = true
 ignore_public_acls = true
 restrict_public_buckets = true

}
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {

  bucket = aws_s3_bucket.documents.id
  rule {
 apply_server_side_encryption_by_default {
 sse_algorithm = "AES256"
}
}

}
resource "aws_s3_bucket_lifecycle_configuration" "documents" {

  bucket = aws_s3_bucket.documents.id
  rule {
 id = "remove-old-demo-documents"
 status = "Enabled"
    filter {
 prefix = "employees/"
}
    expiration {
 days = 30
}

}

}
resource "random_password" "rds" {

  length = 24
  special = false

}
resource "aws_secretsmanager_secret" "database_password" {

  name_prefix = "${local.prefix}-db-password-"
  recovery_window_in_days = 0 # Immediate deletion only for disposable demo resources.

}
resource "aws_secretsmanager_secret_version" "database_password" {

  secret_id = aws_secretsmanager_secret.database_password.id
  secret_string = random_password.rds.result

}
resource "aws_db_instance" "mysql" {

  identifier = "${local.prefix}-mysql"
  engine = "mysql"
 instance_class = var.db_instance_class
  allocated_storage = 20
 storage_type = "gp3"
  db_name = "workforce" # Both services own distinct tables in ONE cheap demo schema.
  username = "workforce_admin"
 password = random_password.rds.result
  port = 3306
  storage_encrypted = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible = false
 multi_az = false
  backup_retention_period = 0
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately = true

}
resource "aws_cognito_user_pool" "users" {

  name = "${local.prefix}-users"
  admin_create_user_config {
 allow_admin_create_user_only = true
}
  password_policy {
 minimum_length = 12
 require_lowercase = true
 require_uppercase = true
 require_numbers = true
 require_symbols = true
}

}
resource "aws_cognito_user_pool_client" "api" {

  name = "${local.prefix}-cli"
  user_pool_id = aws_cognito_user_pool.users.id
  generate_secret = false
  explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH","ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"

}
resource "aws_cognito_user_group" "employee" {
 name = "EMPLOYEE"
 user_pool_id = aws_cognito_user_pool.users.id
}
resource "aws_cognito_user_group" "manager" {
 name = "MANAGER"
 user_pool_id = aws_cognito_user_pool.users.id
}
resource "aws_cognito_user_group" "hr" {
 name = "HR"
 user_pool_id = aws_cognito_user_pool.users.id
}
