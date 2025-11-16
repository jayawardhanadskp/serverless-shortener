terraform {
  backend "s3" {
    bucket         = "serverless-shortener-s3"
    key            = "serverless-shortener.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
