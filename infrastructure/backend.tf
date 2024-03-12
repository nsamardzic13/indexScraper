terraform {
  backend "s3" {
    bucket  = "tf-my-backend-bucket"
    encrypt = true
    key     = "tf-indexads-terraform.tfstate"
    region  = "eu-central-1"
  }
}