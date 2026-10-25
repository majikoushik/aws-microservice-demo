resource "aws_apigatewayv2_api" "http" {

  name="${local.prefix}-api"
protocol_type="HTTP"
  cors_configuration {

    allow_origins=["http://localhost:5173"] # Update if you create a web frontend.
    allow_methods=["GET","POST","PUT","OPTIONS"]
    allow_headers=["authorization","content-type","x-request-id"]

}

}
resource "aws_apigatewayv2_vpc_link" "main" {

  name="${local.prefix}-vpc-link"
  subnet_ids=aws_subnet.public[*].id
  security_group_ids=[aws_security_group.gateway.id]

}
resource "aws_apigatewayv2_authorizer" "cognito" {

  api_id=aws_apigatewayv2_api.http.id
  name="cognito-jwt"
  authorizer_type="JWT"
  identity_sources=["$request.header.Authorization"]
  jwt_configuration {
 audience=[aws_cognito_user_pool_client.api.id]
 issuer=local.issuer
}

}
resource "aws_apigatewayv2_integration" "employee" {

  api_id=aws_apigatewayv2_api.http.id
  integration_type="HTTP_PROXY"
integration_method="ANY"
  integration_uri=aws_service_discovery_service.employee.arn
  connection_type="VPC_LINK"
connection_id=aws_apigatewayv2_vpc_link.main.id
  payload_format_version="1.0"
  request_parameters={
 "overwrite:path"="$request.path"
}

}
resource "aws_apigatewayv2_integration" "leave" {

  api_id=aws_apigatewayv2_api.http.id
  integration_type="HTTP_PROXY"
integration_method="ANY"
  integration_uri=aws_service_discovery_service.leave.arn
  connection_type="VPC_LINK"
connection_id=aws_apigatewayv2_vpc_link.main.id
  payload_format_version="1.0"
  request_parameters={
 "overwrite:path"="$request.path"
}

}
resource "aws_apigatewayv2_route" "employee_root" {

  api_id=aws_apigatewayv2_api.http.id
route_key="ANY /api/employees"
  target="integrations/${aws_apigatewayv2_integration.employee.id}"
  authorization_type="JWT"
authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
resource "aws_apigatewayv2_route" "employee_proxy" {

  api_id=aws_apigatewayv2_api.http.id
route_key="ANY /api/employees/{proxy+}"
  target="integrations/${aws_apigatewayv2_integration.employee.id}"
  authorization_type="JWT"
authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
resource "aws_apigatewayv2_route" "leave_root" {

  api_id=aws_apigatewayv2_api.http.id
route_key="ANY /api/leaves"
  target="integrations/${aws_apigatewayv2_integration.leave.id}"
  authorization_type="JWT"
authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
resource "aws_apigatewayv2_route" "leave_proxy" {

  api_id=aws_apigatewayv2_api.http.id
route_key="ANY /api/leaves/{proxy+}"
  target="integrations/${aws_apigatewayv2_integration.leave.id}"
  authorization_type="JWT"
authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
resource "aws_apigatewayv2_stage" "default" {

  api_id=aws_apigatewayv2_api.http.id
name="$default"
auto_deploy=true

}
# Attendance is owned by the Leave Service and must have its own route keys.
resource "aws_apigatewayv2_route" "attendance_root" {

  api_id=aws_apigatewayv2_api.http.id
  route_key="ANY /api/attendance"
  target="integrations/${aws_apigatewayv2_integration.leave.id}"
  authorization_type="JWT"
  authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
resource "aws_apigatewayv2_route" "attendance_proxy" {

  api_id=aws_apigatewayv2_api.http.id
  route_key="ANY /api/attendance/{proxy+}"
  target="integrations/${aws_apigatewayv2_integration.leave.id}"
  authorization_type="JWT"
  authorizer_id=aws_apigatewayv2_authorizer.cognito.id

}
