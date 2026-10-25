resource "aws_sqs_queue" "dead_letter" {

  name = "${local.prefix}-notifications-dlq"
  message_retention_seconds = 1209600

}
resource "aws_sqs_queue" "notifications" {

  name = "${local.prefix}-notifications"
  visibility_timeout_seconds = 90 # Must exceed the Lambda timeout.
  redrive_policy = jsonencode({
 deadLetterTargetArn = aws_sqs_queue.dead_letter.arn, maxReceiveCount = 3
})

}
resource "aws_dynamodb_table" "processed" {

  name = "${local.prefix}-processed-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "eventId"
  attribute {
 name = "eventId"
 type = "S"
}
  ttl {
 attribute_name = "expiresAt"
 enabled = true
}

}
data "archive_file" "notification" {

  type = "zip"
  source_file = "${path.module}/../../notification-lambda/handler.py"
  output_path = "${path.module}/notification-lambda-generated.zip"

}
resource "aws_iam_role" "lambda" {

  name = "${local.prefix}-lambda-execution"
  assume_role_policy = jsonencode({
 Version="2012-10-17", Statement=[{
Effect="Allow",Principal={
Service="lambda.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy_attachment" "lambda_basic" {

  role = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}
resource "aws_iam_role_policy_attachment" "lambda_sqs" {

  role = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"

}
resource "aws_iam_role_policy" "lambda_dynamo" {

  name = "event-dedup"
 role = aws_iam_role.lambda.id
  policy = jsonencode({
 Version="2012-10-17", Statement=[{
 Effect="Allow",Action=["dynamodb:PutItem"],Resource=aws_dynamodb_table.processed.arn
}]
})

}
resource "aws_lambda_function" "notification" {

  function_name = "${local.prefix}-notification"
  runtime = "python3.12"
  role = aws_iam_role.lambda.arn
  filename = data.archive_file.notification.output_path
  source_code_hash = data.archive_file.notification.output_base64sha256
  handler = "handler.lambda_handler"
  timeout = 15
  memory_size = 128
  environment {
 variables = {
 DEDUP_TABLE = aws_dynamodb_table.processed.name
}
}
  depends_on = [aws_iam_role_policy_attachment.lambda_basic,aws_iam_role_policy_attachment.lambda_sqs,aws_iam_role_policy.lambda_dynamo]

}
resource "aws_lambda_event_source_mapping" "notification" {

  event_source_arn = aws_sqs_queue.notifications.arn
  function_name = aws_lambda_function.notification.arn
  batch_size = 5
  function_response_types = ["ReportBatchItemFailures"]

}
