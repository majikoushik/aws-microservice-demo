data "archive_file" "notification" { type = "zip"; source_file = "${path.module}/lambda/handler.py"; output_path = "${path.module}/lambda/notification.zip" }
resource "aws_cloudwatch_log_group" "lambda" { name = "/aws/lambda/${local.prefix}-notification-processor"; retention_in_days = var.environment == "prod" ? 30 : 7 }
resource "aws_lambda_function" "notification" {
  function_name = "${local.prefix}-notification-processor"; role = aws_iam_role.lambda.arn
  runtime = "python3.13"; handler = "handler.lambda_handler"
  filename = data.archive_file.notification.output_path
  source_code_hash = data.archive_file.notification.output_base64sha256
  timeout = 10; memory_size = 128
  environment { variables = { DEDUP_TABLE = aws_dynamodb_table.dedup.name } }
  depends_on = [aws_iam_role_policy_attachment.lambda_logging, aws_iam_role_policy_attachment.lambda_sqs, aws_iam_role_policy.lambda_dedup, aws_cloudwatch_log_group.lambda]
}
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name = aws_lambda_function.notification.arn
  batch_size = 1; enabled = true
  function_response_types = ["ReportBatchItemFailures"]
  depends_on = [aws_iam_role_policy_attachment.lambda_sqs]
}
