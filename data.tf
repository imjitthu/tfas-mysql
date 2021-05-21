terraform {
  backend "s3" {
    bucket = "terraform-state-jithendar"
    key    = "rs-instances/mysql.tfstate"
    region = "us-east-1"
  }
}