resource "aws_db_subnet_group" "this" { name = "${local.prefix}-db-subnets"; subnet_ids = aws_subnet.private[*].id }
resource "aws_db_instance" "mysql" {
  identifier = "${local.prefix}-mysql"
  engine = "mysql"; engine_version = "8.4"; instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage; storage_type = "gp3"; storage_encrypted = true
  db_name = "workforce"; username = var.db_username; password = var.db_password
  port = 3306; db_subnet_group_name = aws_db_subnet_group.this.name; vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible = false; multi_az = var.db_multi_az
  backup_retention_period = var.environment == "prod" ? 7 : 1
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.prefix}-mysql-final" : null
  apply_immediately = false
}
resource "aws_secretsmanager_secret" "db_password" { name = "${local.prefix}-db-password"; recovery_window_in_days = 7 }
resource "aws_secretsmanager_secret_version" "db_password" { secret_id = aws_secretsmanager_secret.db_password.id; secret_string = var.db_password }
resource "random_id" "bucket" { byte_length = 4 }
resource "aws_s3_bucket" "documents" { bucket = "${local.prefix}-docs-${data.aws_caller_identity.current.account_id}-${random_id.bucket.hex}"; force_destroy = false }
resource "aws_s3_bucket_public_access_block" "documents" { bucket = aws_s3_bucket.documents.id; block_public_acls = true; block_public_policy = true; ignore_public_acls = true; restrict_public_buckets = true }
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" { bucket = aws_s3_bucket.documents.id; rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } } }
resource "aws_s3_bucket_versioning" "documents" { bucket = aws_s3_bucket.documents.id; versioning_configuration { status = "Enabled" } }
resource "aws_sqs_queue" "dlq" { name = "${local.prefix}-notifications-dlq"; message_retention_seconds = 1209600; sqs_managed_sse_enabled = true }
resource "aws_sqs_queue" "main" {
  name = "${local.prefix}-notifications"; visibility_timeout_seconds = 120
  message_retention_seconds = 345600; sqs_managed_sse_enabled = true
  redrive_policy = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dlq.arn, maxReceiveCount = 3 })
}
resource "aws_dynamodb_table" "dedup" {
  name = "${local.prefix}-processed-events"; billing_mode = "PAY_PER_REQUEST"; hash_key = "eventId"
  attribute { name = "eventId"; type = "S" }
  ttl { attribute_name = "expiresAt"; enabled = true }
  point_in_time_recovery { enabled = var.environment == "prod" }
}
resource "aws_ecr_repository" "employee" { name = "${local.prefix}-employee"; image_tag_mutability = "MUTABLE"; image_scanning_configuration { scan_on_push = true } }
resource "aws_ecr_repository" "leave" { name = "${local.prefix}-leave"; image_tag_mutability = "MUTABLE"; image_scanning_configuration { scan_on_push = true } }
resource "aws_cloudwatch_log_group" "employee" { name = "/ecs/${local.prefix}-employee"; retention_in_days = var.environment == "prod" ? 30 : 7 }
resource "aws_cloudwatch_log_group" "leave" { name = "/ecs/${local.prefix}-leave"; retention_in_days = var.environment == "prod" ? 30 : 7 }
