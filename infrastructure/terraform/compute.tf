resource "aws_cloudwatch_log_group" "employee" {

  name = "/ecs/${local.prefix}/employee"
 retention_in_days = 7

}
resource "aws_cloudwatch_log_group" "leave" {

  name = "/ecs/${local.prefix}/leave"
 retention_in_days = 7

}
resource "aws_iam_role" "ecs_execution" {

  name = "${local.prefix}-ecs-execution"
  assume_role_policy = jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Principal={
Service="ecs-tasks.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy_attachment" "ecs_execution" {

  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}
resource "aws_iam_role_policy" "ecs_secret" {

  name="read-rds-secret"
role=aws_iam_role.ecs_execution.id
  policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Action=["secretsmanager:GetSecretValue"],Resource=aws_secretsmanager_secret.database_password.arn
}]
})

}
resource "aws_iam_role" "employee_task" {

  name="${local.prefix}-employee-task"
  assume_role_policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Principal={
Service="ecs-tasks.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy" "employee_s3" {

  name="employee-documents"
role=aws_iam_role.employee_task.id
  policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Action=["s3:GetObject","s3:PutObject"],Resource="${aws_s3_bucket.documents.arn}/employees/*"
}]
})

}
resource "aws_iam_role" "leave_task" {

  name="${local.prefix}-leave-task"
  assume_role_policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Principal={
Service="ecs-tasks.amazonaws.com"
},Action="sts:AssumeRole"
}]
})

}
resource "aws_iam_role_policy" "leave_sqs" {

  name="send-notifications"
role=aws_iam_role.leave_task.id
  policy=jsonencode({
Version="2012-10-17",Statement=[{
Effect="Allow",Action=["sqs:SendMessage"],Resource=aws_sqs_queue.notifications.arn
}]
})

}
resource "aws_ecs_cluster" "main" {
 name="${local.prefix}-cluster"
}
resource "aws_ecs_task_definition" "employee" {

  family = "${local.prefix}-employee"
  network_mode="awsvpc"
requires_compatibilities=["FARGATE"]
  cpu="512"
memory="1024"
  execution_role_arn=aws_iam_role.ecs_execution.arn
  task_role_arn=aws_iam_role.employee_task.arn
  container_definitions=jsonencode([{
name="employee",image=local.ecr_employee,essential=true,
    portMappings=[{
containerPort=8081,hostPort=8081,protocol="tcp"
}],
    environment=[
      {
name="SPRING_PROFILES_ACTIVE",value="aws"
},
      {
name="SERVER_PORT",value="8081"
},
      {
name="AWS_REGION",value=var.aws_region
},
      {
name="DB_HOST",value=aws_db_instance.mysql.address
},
      {
name="DB_NAME",value="workforce"
},
      {
name="DB_USERNAME",value=aws_db_instance.mysql.username
},
      {
name="COGNITO_ISSUER",value=local.issuer
},
      {
name="COGNITO_CLIENT_ID",value=aws_cognito_user_pool_client.api.id
},
      {
name="DOCUMENT_BUCKET",value=aws_s3_bucket.documents.id
}
    ],
    secrets=[{
name="DB_PASSWORD",valueFrom=aws_secretsmanager_secret.database_password.arn
}],
    healthCheck={
command=["CMD-SHELL","wget -q -O - http://localhost:8081/actuator/health | grep -q UP"],interval=30,timeout=5,retries=3,startPeriod=90
},
    logConfiguration={
logDriver="awslogs",options={
"awslogs-group"=aws_cloudwatch_log_group.employee.name,"awslogs-region"=var.aws_region,"awslogs-stream-prefix"="ecs"
}
}

}])
  depends_on=[aws_secretsmanager_secret_version.database_password,aws_iam_role_policy.ecs_secret]

}
resource "aws_ecs_task_definition" "leave" {

  family = "${local.prefix}-leave"
  network_mode="awsvpc"
requires_compatibilities=["FARGATE"]
  cpu="512"
memory="1024"
  execution_role_arn=aws_iam_role.ecs_execution.arn
  task_role_arn=aws_iam_role.leave_task.arn
  container_definitions=jsonencode([{
name="leave",image=local.ecr_leave,essential=true,
    portMappings=[{
containerPort=8082,hostPort=8082,protocol="tcp"
}],
    environment=[
      {
name="SPRING_PROFILES_ACTIVE",value="aws"
},
      {
name="SERVER_PORT",value="8082"
},
      {
name="AWS_REGION",value=var.aws_region
},
      {
name="DB_HOST",value=aws_db_instance.mysql.address
},
      {
name="DB_NAME",value="workforce"
},
      {
name="DB_USERNAME",value=aws_db_instance.mysql.username
},
      {
name="COGNITO_ISSUER",value=local.issuer
},
      {
name="COGNITO_CLIENT_ID",value=aws_cognito_user_pool_client.api.id
},
      {
name="EMPLOYEE_SERVICE_URL",value="http://employee.${local.prefix}.internal:8081"
},
      {
name="SQS_QUEUE_URL",value=aws_sqs_queue.notifications.id
}
    ],
    secrets=[{
name="DB_PASSWORD",valueFrom=aws_secretsmanager_secret.database_password.arn
}],
    healthCheck={
command=["CMD-SHELL","wget -q -O - http://localhost:8082/actuator/health | grep -q UP"],interval=30,timeout=5,retries=3,startPeriod=90
},
    logConfiguration={
logDriver="awslogs",options={
"awslogs-group"=aws_cloudwatch_log_group.leave.name,"awslogs-region"=var.aws_region,"awslogs-stream-prefix"="ecs"
}
}

}])
  depends_on=[aws_secretsmanager_secret_version.database_password,aws_iam_role_policy.ecs_secret]

}
resource "aws_service_discovery_private_dns_namespace" "main" {

  name="${local.prefix}.internal"
 vpc=aws_vpc.main.id

}
resource "aws_service_discovery_service" "employee" {

  name="employee"
  dns_config {
 namespace_id=aws_service_discovery_private_dns_namespace.main.id
    dns_records {
 ttl=10
type="A"
}
    dns_records {
 ttl=10
type="SRV"
}
    routing_policy="MULTIVALUE"

}
  health_check_custom_config {
 failure_threshold=1
}

}
resource "aws_service_discovery_service" "leave" {

  name="leave"
  dns_config {
 namespace_id=aws_service_discovery_private_dns_namespace.main.id
    dns_records {
 ttl=10
type="A"
}
    dns_records {
 ttl=10
type="SRV"
}
    routing_policy="MULTIVALUE"

}
  health_check_custom_config {
 failure_threshold=1
}

}
resource "aws_ecs_service" "employee" {

  name="${local.prefix}-employee"
cluster=aws_ecs_cluster.main.id
  task_definition=aws_ecs_task_definition.employee.arn
  desired_count=1
launch_type="FARGATE"
  deployment_minimum_healthy_percent=0
  deployment_maximum_percent=200
  network_configuration {
 subnets=aws_subnet.public[*].id
 security_groups=[aws_security_group.tasks.id]
 assign_public_ip=true
}
  service_registries {
 registry_arn=aws_service_discovery_service.employee.arn
port=8081
}
  depends_on=[aws_iam_role_policy_attachment.ecs_execution,aws_iam_role_policy.employee_s3,aws_route.internet]
  lifecycle {
 ignore_changes=[task_definition]
} # CI/CD owns image version after initial creation.

}
resource "aws_ecs_service" "leave" {

  name="${local.prefix}-leave"
cluster=aws_ecs_cluster.main.id
  task_definition=aws_ecs_task_definition.leave.arn
  desired_count=1
launch_type="FARGATE"
  deployment_minimum_healthy_percent=0
  deployment_maximum_percent=200
  network_configuration {
 subnets=aws_subnet.public[*].id
 security_groups=[aws_security_group.tasks.id]
 assign_public_ip=true
}
  service_registries {
 registry_arn=aws_service_discovery_service.leave.arn
port=8082
}
  depends_on=[aws_iam_role_policy_attachment.ecs_execution,aws_iam_role_policy.leave_sqs,aws_route.internet]
  lifecycle {
 ignore_changes=[task_definition]
}

}
