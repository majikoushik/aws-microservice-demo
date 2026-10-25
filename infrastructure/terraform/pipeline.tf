# Optional AWS-native CI/CD. Set enable_pipeline=true only AFTER core deployment.
# After terraform apply, the CodeConnections connection is PENDING until you
# complete the GitHub handshake in Developer Tools > Connections.
resource "aws_codestarconnections_connection" "github" {

  count = var.enable_pipeline ? 1 : 0
  name = "${local.prefix}-github"
  provider_type = "GitHub"

}
resource "aws_s3_bucket" "pipeline" {

  count = var.enable_pipeline ? 1 : 0
  bucket_prefix = "${local.prefix}-pipeline-"
  force_destroy = true

}
resource "aws_s3_bucket_public_access_block" "pipeline" {

  count = var.enable_pipeline ? 1 : 0
  bucket = aws_s3_bucket.pipeline[0].id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true

}
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline" {

  count = var.enable_pipeline ? 1 : 0
  bucket = aws_s3_bucket.pipeline[0].id
  rule {
 apply_server_side_encryption_by_default {
 sse_algorithm="AES256"
}
}

}
resource "aws_iam_role" "codebuild" {

  count = var.enable_pipeline ? 1 : 0
  name="${local.prefix}-codebuild"
  assume_role_policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Principal={
Service="codebuild.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy" "codebuild" {

  count=var.enable_pipeline ? 1 : 0
  role=aws_iam_role.codebuild[0].id
  name="build-image-push"
  policy=jsonencode({
Version="2012-10-17",Statement=[
    {
Effect="Allow",Action=["ecr:GetAuthorizationToken","logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],Resource="*"
},
    {
Effect="Allow",Action=["ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload","ecr:InitiateLayerUpload","ecr:PutImage","ecr:UploadLayerPart","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"],Resource=[aws_ecr_repository.employee.arn,aws_ecr_repository.leave.arn]
},
    {
Effect="Allow",Action=["s3:GetObject","s3:PutObject"],Resource="${aws_s3_bucket.pipeline[0].arn}/*"
}
  ]
})

}
resource "aws_codebuild_project" "build" {

  count=var.enable_pipeline ? 1 : 0
  name="${local.prefix}-build"
  service_role=aws_iam_role.codebuild[0].arn
  artifacts {
 type="CODEPIPELINE"
}
  source {
 type="CODEPIPELINE"
 buildspec="buildspec.yml"
}
  environment {

    compute_type="BUILD_GENERAL1_SMALL"
    image="aws/codebuild/standard:7.0"
    type="LINUX_CONTAINER"
    privileged_mode=true # Required for Docker image builds.
    environment_variable {
 name="AWS_ACCOUNT_ID"
value=local.account_id
}
    environment_variable {
 name="AWS_DEFAULT_REGION"
value=var.aws_region
}
    environment_variable {
 name="EMPLOYEE_ECR_REPO"
value=aws_ecr_repository.employee.repository_url
}
    environment_variable {
 name="LEAVE_ECR_REPO"
value=aws_ecr_repository.leave.repository_url
}

}

}
resource "aws_iam_role" "codepipeline" {

  count=var.enable_pipeline ? 1 : 0
  name="${local.prefix}-codepipeline"
  assume_role_policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Principal={
Service="codepipeline.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy" "codepipeline" {

  count=var.enable_pipeline ? 1 : 0
  name="deploy-ecs"
  role=aws_iam_role.codepipeline[0].id
  # Intentionally broad ECS permissions for educational bootstrapping.
  # Replace "*" with resource ARNs and restrict iam:PassRole in a hardened account.
  policy=jsonencode({
Version="2012-10-17",Statement=[
    {
Effect="Allow",Action=["codeconnections:UseConnection","codestar-connections:UseConnection"],Resource=aws_codestarconnections_connection.github[0].arn
},
    {
Effect="Allow",Action=["s3:GetObject","s3:GetObjectVersion","s3:PutObject","s3:GetBucketVersioning"],Resource=[aws_s3_bucket.pipeline[0].arn,"${aws_s3_bucket.pipeline[0].arn}/*"]
},
    {
Effect="Allow",Action=["codebuild:StartBuild","codebuild:BatchGetBuilds"],Resource=aws_codebuild_project.build[0].arn
},
    {
Effect="Allow",Action=["ecs:DescribeServices","ecs:DescribeTaskDefinition","ecs:UpdateService","ecs:RegisterTaskDefinition","ecs:TagResource"],Resource="*"
},
    {
Effect="Allow",Action=["iam:PassRole"],Resource=[aws_iam_role.ecs_execution.arn,aws_iam_role.employee_task.arn,aws_iam_role.leave_task.arn]
}
  ]
})

}
resource "aws_codepipeline" "main" {

  count=var.enable_pipeline ? 1 : 0
  name="${local.prefix}-pipeline"
  role_arn=aws_iam_role.codepipeline[0].arn
  artifact_store {
 location=aws_s3_bucket.pipeline[0].bucket
type="S3"
}
  stage {

    name="Source"
    action {

      name="GitHub"
category="Source"
owner="AWS"
provider="CodeStarSourceConnection"
version="1"
      output_artifacts=["SourceOutput"]
      configuration={
ConnectionArn=aws_codestarconnections_connection.github[0].arn,
        FullRepositoryId="${var.github_owner}/${var.github_repo}",BranchName=var.github_branch,
        OutputArtifactFormat="CODE_ZIP",DetectChanges="true"
}

}

}
  stage {

    name="Build"
    action {

      name="BuildAndTest"
category="Build"
owner="AWS"
provider="CodeBuild"
version="1"
      input_artifacts=["SourceOutput"]
output_artifacts=["BuildOutput"]
      configuration={
ProjectName=aws_codebuild_project.build[0].name
}

}

}
  stage {

    name="Deploy"
    action {

      name="DeployEmployee"
category="Deploy"
owner="AWS"
provider="ECS"
version="1"
      input_artifacts=["BuildOutput"]
run_order=1
      configuration={
ClusterName=aws_ecs_cluster.main.name,ServiceName=aws_ecs_service.employee.name,
        FileName="employee-imagedefinitions.json"
}

}
    action {

      name="DeployLeave"
category="Deploy"
owner="AWS"
provider="ECS"
version="1"
      input_artifacts=["BuildOutput"]
run_order=1
      configuration={
ClusterName=aws_ecs_cluster.main.name,ServiceName=aws_ecs_service.leave.name,
        FileName="leave-imagedefinitions.json"
}

}

}

}
