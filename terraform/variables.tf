variable "aws_region" {
  default = "us-east-1"
}

variable "domain_name" {
  description = "serverless-shortener.com"
  type = string
}

variable "hosted_zone_id" {
  description = "value"
  type = string
}