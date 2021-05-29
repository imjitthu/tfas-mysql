resource "aws_rds_cluster_parameter_group" "mysql" {
  name   = "mysql-cluster-parameter-group-${var.env}-roboshop"
  family = "aurora-mysql5.7"
  description = "RDS default cluster parameter group"
}

resource "aws_rds_cluster" "mysql" {
  cluster_identifier              = "mysql-cluster-${var.env}-roboshop"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.mysql_aurora.2.03.2"
  database_name                   = "defaultdb"
  master_username                 = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]
  master_password                 = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]
  backup_retention_period         = 5
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.mysql.name
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "mysql-server-${count.index +1}"
  cluster_identifier = aws_rds_cluster.mysql.id
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.mysql.engine
  engine_version     = aws_rds_cluster.mysql.engine_version
}

resource "null_resource" "import-mysql-schema" {
  provisioner "local-exec" {
    command     = <<EOF
    sleep 600
    rm -rf rs-mysql
    git clone https://github.com/imjitthu/rs-mysql.git
    mysql -h ${aws_rds_cluster.mysql.endpoint} -u${jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_USER"]} -p${jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["SSH_PASS"]} < rs-mysql/shipping.sql
  EOF
  }
}

resource "aws_route53_record" "jithendar" {
  name          = "${var.COMPONENT}.${data.aws_route53_zone.jithendar.name}"
  type          = "CNAME"
  ttl           = "300"
  zone_id       = data.aws_route53_zone.jithendar.zone_id
  records       = [aws_rds_cluster.mysql.endpoint]
}