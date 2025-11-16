output "api-url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "cloudfront_url" {
  value = "https://${var.domain_name}"
}

output "dynamodb_table" {
  value = aws_dynamodb_table.urls.name
}