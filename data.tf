terraform {
  backend "s3" {
    bucket = "terraform-state-rs-practice"
    key    = "rs-instances/mysql.tfstate"
    region = "us-east-1"
  }
}

#get the SSH credentials from AWS Secret Manager
data "aws_secretsmanager_secret" "creds" {
  name = "SSH_ROOT"
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.creds.id
}

#Get the latest AMI from AWS with OWNER ID and Name Filter
data "aws_ami" "ami" {
  most_recent = true
  owners      = ["973714476881"]
  # filters {
  #   name = "image-d"
  #   values = ["ami-079a3f3cf00741286"]
  # } ami id will change all time so filtering on name
    filter {
      name = "name"
      values = ["Centos-7-DevOps-Practice"]
    }
}