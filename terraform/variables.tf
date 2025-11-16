variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Custom domain to use for CloudFront (e.g. short.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for domain_name"
  type        = string
}

variable "g_owner" {
  description = "GitHub owner/org for OIDC trust (e.g. kasun-jayawardhana)"
  type        = string
}

variable "g_repo" {
  description = "GitHub repo name for OIDC trust (e.g. serverless-shortener)"
  type        = string
}
