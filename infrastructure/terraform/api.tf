resource "aws_apigatewayv2_api" "this" { name = "${local.prefix}-api"; protocol_type = "HTTP" }
resource "aws_apigatewayv2_vpc_link" "this" {
  name = "${local.prefix}-vpc-link"
  security_group_ids = [aws_security_group.vpclink.id]
  subnet_ids = aws_subnet.private[*].id
}
resource "aws_apigatewayv2_integration" "alb" {
  api_id = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"; integration_method = "ANY"
  integration_uri = aws_lb_listener.http.arn
  connection_type = "VPC_LINK"; connection_id = aws_apigatewayv2_vpc_link.this.id
  payload_format_version = "1.0"
  request_parameters = { "overwrite:path" = "$request.path" }
}
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id = aws_apigatewayv2_api.this.id
  authorizer_type = "JWT"; name = "${local.prefix}-cognito-authorizer"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration { audience = [aws_cognito_user_pool_client.postman.id]; issuer = "https://${aws_cognito_user_pool.this.endpoint}" }
}
resource "aws_apigatewayv2_route" "proxy" {
  api_id = aws_apigatewayv2_api.this.id; route_key = "ANY /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.alb.id}"
  authorization_type = "JWT"; authorizer_id = aws_apigatewayv2_authorizer.jwt.id
}
resource "aws_cloudwatch_log_group" "api" { name = "/aws/apigateway/${local.prefix}-api"; retention_in_days = var.environment == "prod" ? 30 : 7 }
resource "aws_apigatewayv2_stage" "this" {
  api_id = aws_apigatewayv2_api.this.id; name = var.environment
  auto_deploy = true
  default_route_settings { throttling_burst_limit = 30; throttling_rate_limit = 15 }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({ requestId = "$context.requestId", status = "$context.status", routeKey = "$context.routeKey", integrationStatus = "$context.integrationStatus", integrationError = "$context.integrationErrorMessage", requestTime = "$context.requestTime" })
  }
}
