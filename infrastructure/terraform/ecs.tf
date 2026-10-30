resource "aws_ecs_cluster" "this" { name = "${local.prefix}-cluster"; setting { name = "containerInsights"; value = var.environment == "prod" ? "enabled" : "disabled" } }
locals {
  shared_env = [
    { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
    { name = "DB_HOST", value = aws_db_instance.mysql.address },
    { name = "DB_PORT", value = "3306" },
    { name = "DB_USERNAME", value = var.db_username },
    { name = "COGNITO_ISSUER", value = "https://${aws_cognito_user_pool.this.endpoint}" },
    { name = "COGNITO_CLIENT_ID", value = aws_cognito_user_pool_client.postman.id }
  ]
  db_secret = [{ name = "DB_PASSWORD", valueFrom = aws_secretsmanager_secret.db_password.arn }]
  employee_containers = [{
    name = "employee", image = local.image_employee, essential = true
    portMappings = [{ containerPort = 8081, hostPort = 8081, protocol = "tcp" }]
    environment = concat(local.shared_env, [
      { name = "DB_NAME", value = "workforce" },
      { name = "DOCUMENT_BUCKET", value = aws_s3_bucket.documents.bucket }
    ])
    secrets = local.db_secret
    logConfiguration = { logDriver = "awslogs", options = {
      "awslogs-group" = aws_cloudwatch_log_group.employee.name,
      "awslogs-region" = var.region, "awslogs-stream-prefix" = "ecs"
    } }
  }]
  leave_containers = [{
    name = "leave", image = local.image_leave, essential = true
    portMappings = [{ containerPort = 8082, hostPort = 8082, protocol = "tcp" }]
    environment = concat(local.shared_env, [
      { name = "DB_NAME", value = "workforce_leave" },
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_db_instance.mysql.address}:3306/workforce_leave?createDatabaseIfNotExist=true" },
      { name = "EMPLOYEE_SERVICE_URL", value = "http://${aws_lb.internal.dns_name}" },
      { name = "SQS_QUEUE_URL", value = aws_sqs_queue.main.url }
    ])
    secrets = local.db_secret
    logConfiguration = { logDriver = "awslogs", options = {
      "awslogs-group" = aws_cloudwatch_log_group.leave.name,
      "awslogs-region" = var.region, "awslogs-stream-prefix" = "ecs"
    } }
  }]
}
resource "aws_ecs_task_definition" "employee" {
  family = "${local.prefix}-employee-task"; network_mode = "awsvpc"; requires_compatibilities = ["FARGATE"]
  cpu = var.ecs_cpu; memory = var.ecs_memory
  execution_role_arn = aws_iam_role.ecs_execution.arn; task_role_arn = aws_iam_role.employee_task.arn
  container_definitions = jsonencode(local.employee_containers)
  depends_on = [aws_iam_role_policy.execution_secret]
}
resource "aws_ecs_task_definition" "leave" {
  family = "${local.prefix}-leave-task"; network_mode = "awsvpc"; requires_compatibilities = ["FARGATE"]
  cpu = var.ecs_cpu; memory = var.ecs_memory
  execution_role_arn = aws_iam_role.ecs_execution.arn; task_role_arn = aws_iam_role.leave_task.arn
  container_definitions = jsonencode(local.leave_containers)
  depends_on = [aws_iam_role_policy.execution_secret]
}
resource "aws_ecs_service" "employee" {
  count = var.enable_services ? 1 : 0
  name = "${local.prefix}-employee-service"; cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.employee.arn; desired_count = var.ecs_desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.private_ecs_with_nat ? aws_subnet.private[*].id : aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = !var.private_ecs_with_nat
  }
  load_balancer { target_group_arn = aws_lb_target_group.employee.arn; container_name = "employee"; container_port = 8081 }
  depends_on = [aws_lb_listener.http]
}
resource "aws_ecs_service" "leave" {
  count = var.enable_services ? 1 : 0
  name = "${local.prefix}-leave-service"; cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.leave.arn; desired_count = var.ecs_desired_count
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.private_ecs_with_nat ? aws_subnet.private[*].id : aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = !var.private_ecs_with_nat
  }
  load_balancer { target_group_arn = aws_lb_target_group.leave.arn; container_name = "leave"; container_port = 8082 }
  depends_on = [aws_lb_listener_rule.leave]
}
