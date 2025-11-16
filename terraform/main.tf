# DynamoDB Table
resource "aws_dynamodb_table" "urls" {
  name         = "UrlShortener"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "shortCode"

  attribute {
    name = "shortCode"
    type = "S"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "url-shortener-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Lambda: Shorten
resource "aws_lambda_function" "shorten" {
  filename         = "lambda/shorten.zip"
  function_name    = "url-shortener-shorten"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.shortenHandler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda/shorten.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.urls.name
      BASE_URL   = "https://${var.domain_name}"
    }
  }
}

# Lambda: Redirect
resource "aws_lambda_function" "redirect" {
  filename         = "lambda/redirect.zip"
  function_name    = "url-shortener-redirect"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.redirectHandler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda/redirect.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.urls.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "url-shortener-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# POST /shorten
resource "aws_apigatewayv2_integration" "shorten" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.shorten.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "shorten" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.shorten.id}"
}

# GET /{code}
resource "aws_apigatewayv2_integration" "redirect" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.redirect.invoke_arn
  integration_method = "GET"
}

resource "aws_apigatewayv2_route" "redirect" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /{code}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect.id}"
}


# Lambda Permissions
resource "aws_lambda_permission" "apigw_shorten" {
  statement_id  = "AllowAPIGatewayInvokeShorten"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shorten.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

resource "aws_lambda_permission" "apigw_redirect" {
  statement_id  = "AllowAPIGatewayInvokeRedirect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}


# CloudFront
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = replace(aws_apigatewayv2_api.http_api.api_endpoint, "https://", "")
    origin_id   = "apiGateway"
    origin_path = "/${aws_apigatewayv2_stage.prod.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apiGateway"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name]
}


# ACM Certificate 
resource "aws_acm_certificate" "cert" {
  provider          = aws.useast1
  domain_name       = var.domain_name
  validation_method = "DNS"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

# Route53 Record
data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}