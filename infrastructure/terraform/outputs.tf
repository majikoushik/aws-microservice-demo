output "api_base_url" {
 value=aws_apigatewayv2_api.http.api_endpoint
}
output "aws_region" {
 value=var.aws_region
}
output "ecr_employee" {
 value=aws_ecr_repository.employee.repository_url
}
output "ecr_leave" {
 value=aws_ecr_repository.leave.repository_url
}
output "ecs_cluster" {
 value=aws_ecs_cluster.main.name
}
output "ecs_employee_service" {
 value=aws_ecs_service.employee.name
}
output "ecs_leave_service" {
 value=aws_ecs_service.leave.name
}
output "cognito_user_pool_id" {
 value=aws_cognito_user_pool.users.id
}
output "cognito_client_id" {
 value=aws_cognito_user_pool_client.api.id
}
output "rds_endpoint" {
 value=aws_db_instance.mysql.endpoint
}
output "s3_bucket" {
 value=aws_s3_bucket.documents.id
}
output "sqs_queue_url" {
 value=aws_sqs_queue.notifications.id
}
output "pipeline_connection_arn" {

  value = var.enable_pipeline ? aws_codestarconnections_connection.github[0].arn : "disabled"

}
