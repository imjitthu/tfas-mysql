locals {
  key_name = "test"
  key_path = "test.pem"
}

resource "aws_instance" "mysql" {
  # aws_spot_instabce_request for spot instance
  ami = "${var.AMI}"
  instance_type = "${var.INSTANCE_TYPE}"
  key_name = local.key_name
  # spot_type = "one-time"  aws_spot_instance_request
  tags = {
    "Name" = "${var.COMPONENT}-Server"
  }

 connection {
  host = aws_instance.mysql.public_ip
  type = "ssh"
  user = var.USER
  #private_key = file("${local.key_path}")
  password = var.PASSWORD
}

provisioner "remote-exec" {
  inline = [ "set-hostname ${var.COMPONENT}" ]
}

provisioner "local-exec" {
  command = "echo ${aws_instance.mysql.public_ip} > mysql_inv"
  #command = "ansible-playbook -i ${aws_instance.mysql.public_ip}, --private-key ${local.key_path} ${var.COMPONENT}.yml"
  #echo $IP component=${component} ansible_user=root ansible_password=DevOps321 >>inv
}
}

resource "aws_route53_record" "mysql" {
  zone_id = "${var.R53_ZONE_ID}"
  name = "${var.COMPONENT}.${var.DOMAIN}"
  type = "A"
  ttl = "300"
  records = [ aws_instance.mysql.public_ip ]
}
