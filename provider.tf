provider "aws" {
  profile = "terraform"
  region  = "us-east-1"
  shared_credentials_file = "root/.aws/credentials"
}