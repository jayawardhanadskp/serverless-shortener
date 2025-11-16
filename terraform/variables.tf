variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "short.kasunjayawardhana.com"
}

variable "hosted_zone_id" {
  type    = string
  default = "Z06022612792PVIKY9STS"
}

variable "g_owner" {
  type    = string
  default = "jayawardhanadskp"
}

variable "g_repo" {
  type    = string
  default = "serverless-shortener"
}
