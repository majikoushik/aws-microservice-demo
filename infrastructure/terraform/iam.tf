data "aws_iam_policy_document" "ecs_assume" {
  statement { actions = ["sts:AssumeRole"]; principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] } }
}
resource "aws_iam_role" "ecs_execution" { name = "${local.prefix}-ecs-execution"; assume_role_policy = data.aws_iam_policy_document.ecs_assume.json }
resource "aws_iam_role_policy_attachment" "ecs_execution" { role = aws_iam_role.ecs_execution.name; policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" }
resource "aws_iam_role_policy" "execution_secret" {
  name = "read-db-secret"; role = aws_iam_role.ecs_execution.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = aws_secretsmanager_secret.db_password.arn }] })
}
resource "aws_iam_role" "employee_task" { name = "${local.prefix}-employee-task"; assume_role_policy = data.aws_iam_policy_document.ecs_assume.json }
resource "aws_iam_role" "leave_task" { name = "${local.prefix}-leave-task"; assume_role_policy = data.aws_iam_policy_document.ecs_assume.json }
resource "aws_iam_role_policy" "employee_s3" {
  role = aws_iam_role.employee_task.id; name = "employee-documents"
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.documents.arn}/employees/*" }] })
}
resource "aws_iam_role_policy" "leave_sqs" {
  role = aws_iam_role.leave_task.id; name = "publish-leave-events"
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["sqs:SendMessage"], Resource = aws_sqs_queue.main.arn }] })
}
data "aws_iam_policy_document" "lambda_assume" { statement { actions = ["sts:AssumeRole"]; principals { type = "Service"; identifiers = ["lambda.amazonaws.com"] } } }
resource "aws_iam_role" "lambda" { name = "${local.prefix}-notification-lambda"; assume_role_policy = data.aws_iam_policy_document.lambda_assume.json }
resource "aws_iam_role_policy_attachment" "lambda_logging" { role = aws_iam_role.lambda.name; policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" }
resource "aws_iam_role_policy_attachment" "lambda_sqs" { role = aws_iam_role.lambda.name; policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole" }
resource "aws_iam_role_policy" "lambda_dedup" {
  role = aws_iam_role.lambda.id; name = "dynamodb-dedup"
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["dynamodb:PutItem"], Resource = aws_dynamodb_table.dedup.arn }] })
}
