output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "cloudfront_url" {
  value = "https://${var.domain_name}"
}

output "dynamodb_table" {
  value = aws_dynamodb_table.urls.name
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
  description = "If you prefer to configure GitHub manually, use this role ARN for OIDC"
}
