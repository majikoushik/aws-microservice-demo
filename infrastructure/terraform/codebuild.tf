# Optional bootstrap CodeBuild project. You must connect GitHub to AWS CodeConnections separately.
# It uses the source project's checked-in buildspec.yml.
locals { enable_codebuild = var.github_repo_url != "" && var.codebuild_connection_arn != "" }
data "aws_iam_policy_document" "codebuild_assume" { statement { actions = ["sts:AssumeRole"]; principals { type = "Service"; identifiers = ["codebuild.amazonaws.com"] } } }
resource "aws_iam_role" "codebuild" {
  count = local.enable_codebuild ? 1 : 0
  name = "${local.prefix}-codebuild-role"; assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}
resource "aws_iam_role_policy" "codebuild" {
  count = local.enable_codebuild ? 1 : 0
  role = aws_iam_role.codebuild[0].id; name = "build-push-images"
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
    { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"], Resource = [aws_ecr_repository.employee.arn, aws_ecr_repository.leave.arn] },
    { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.prefix}-images:*" },
    { Effect = "Allow", Action = ["codestar-connections:UseConnection", "codeconnections:UseConnection"], Resource = var.codebuild_connection_arn }
  ] })
}
resource "aws_cloudwatch_log_group" "codebuild" {
  count = local.enable_codebuild ? 1 : 0
  name = "/aws/codebuild/${local.prefix}-images"; retention_in_days = 7
}
resource "aws_codebuild_project" "images" {
  count = local.enable_codebuild ? 1 : 0
  name = "${local.prefix}-images"; service_role = aws_iam_role.codebuild[0].arn
  source_version = var.github_source_version
  artifacts { type = "NO_ARTIFACTS" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/amazonlinux-x86_64-standard:5.0"; type = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable { name = "AWS_ACCOUNT_ID"; value = data.aws_caller_identity.current.account_id }
    environment_variable { name = "AWS_DEFAULT_REGION"; value = var.region }
    environment_variable { name = "EMPLOYEE_ECR_REPO"; value = aws_ecr_repository.employee.repository_url }
    environment_variable { name = "LEAVE_ECR_REPO"; value = aws_ecr_repository.leave.repository_url }
  }
  source {
    type = "GITHUB"; location = var.github_repo_url; buildspec = "buildspec.yml"
    auth { type = "CODECONNECTIONS"; resource = var.codebuild_connection_arn }
  }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild[0].name; status = "ENABLED" } }
  depends_on = [aws_iam_role_policy.codebuild]
}
