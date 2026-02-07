terraform {
  backend "s3" {
    bucket = "tiago-terraform-automation"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}
