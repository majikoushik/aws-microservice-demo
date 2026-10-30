resource "aws_cognito_user_pool" "this" {
  name = "${local.prefix}-users"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  password_policy { minimum_length = 12; require_lowercase = true; require_uppercase = true; require_numbers = true; require_symbols = true }
  admin_create_user_config { allow_admin_create_user_only = true }
  account_recovery_setting { recovery_mechanism { name = "verified_email"; priority = 1 } }
}
resource "aws_cognito_user_group" "roles" {
  for_each = toset(["HR", "MANAGER", "EMPLOYEE"])
  name = each.value; user_pool_id = aws_cognito_user_pool.this.id
}
resource "aws_cognito_user_pool_client" "postman" {
  name = "${local.prefix}-postman-client"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["openid", "email", "profile"]
  callback_urls = [var.postman_callback_url]
  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  refresh_token_validity = 30
  access_token_validity = 60
  id_token_validity = 60
  token_validity_units { refresh_token = "days"; access_token = "minutes"; id_token = "minutes" }
  prevent_user_existence_errors = "ENABLED"
}
resource "aws_cognito_user_pool_domain" "this" {
  managed_login_version = 2
  domain = var.cognito_domain_prefix != "" ? var.cognito_domain_prefix : lower("${var.project}-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.region}")
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_managed_login_branding" "postman" {
  user_pool_id = aws_cognito_user_pool.this.id
  client_id = aws_cognito_user_pool_client.postman.id
  use_cognito_provided_values = true
  depends_on = [aws_cognito_user_pool_domain.this]
}
