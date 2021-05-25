# resource "aws_db_subnet_group" "mysql" {
#   name       = "mysql"
#   subnet_ids = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS
#   tags       = {
#     name     = "Mysql DB subnet grp"
#   }
# }

resource "aws_rds_cluster_parameter_group" "mysql" {
  name   = "mysql-cluster-parameter-group-roboshop"
  family = "aurora-mysql5.7"
  description = "RDS default cluster parameter group"
}

resource "aws_rds_cluster" "mysql" {
  cluster_identifier              = "mysql-cluster-roboshop"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.mysql_aurora.2.03.2"
  #db_subnet_group_name            = aws_db_subnet_group.mysql.name
  database_name                   = "defaultdb"
  master_username                 = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
  master_password                 = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.mysql.name
  #vpc_security_group_ids          = [aws_security_group.allow_mysql.id]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "mysql-server-${count.index +1}"
  cluster_identifier = aws_rds_cluster.mysql.id
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.mysql.engine
  engine_version     = aws_rds_cluster.mysql.engine_version
}


# resource "aws_security_group" "allow_mysql" {
#   name          = "allow-mysql-${var.ENV}"
#   description   = "allow-mysql-${var.ENV}"
#   vpc_id        = data.terraform_remote_state.vpc.outputs.VPC_ID
#   ingress {
#     description = "SSH"
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = [data.terraform_remote_state.vpc.outputs.VPC_CIDR,data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags          = {
#     Name        = "allow-mysql-${var.ENV}"
#   }
# }

resource "null_resource" "import-mysql-schema" {
  provisioner "local-exec" {
    command     = <<EOF
    sleep 600
    rm -rf rs-mysql
    git clone https://github.com/imjitthu/rs-mysql.git
    cd rs-mysql
    mysql -h ${aws_rds_cluster.mysql.endpoint} -u${jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["MYSQL_USER"]} -p${jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["MYSQL_PASS"]} <shipping.sql
  EOF
  }
}

data "aws_route53_zone" "jithendar" {
  name         = "jithendar.com"
  private_zone = false
}

resource "aws_route53_record" "mysql" {
  name          = "${var.COMPONENT}.${var.DOMAIN}"
  type          = "CNAME"
  ttl           = "300"
  #zone_id       = "${var.R53_ZONE_ID}"
  zone_id       = [aws_route53_zone.mysql.zone_id]
  #zone_id       = data.terraform_remote_state.vpc.outputs.ZONE_ID
  records       = [aws_rds_cluster.mysql.endpoint]
}
