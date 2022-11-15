terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.59.0"
    }
  }
}
# # Configure the AWS Provider If you did not configure your aws credentials with aws configure, you can do it here, but you must be careful and dont push this to your repo
# provider "aws" {
#   region = "us-east-1"
#   access_key = "XXXXXXX"
#   secret_key = "xxxx/F4h2a"
# }
variable "key_name" {
  default = "serkey"   # change here
}

locals {
  name = "K3S"   # change here, optional 
 }

resource "aws_instance" "master" {
  ami = "ami-04505e74c0741db8d"
  key_name               = var.key_name
  #key_name               = "serkey"
  vpc_security_group_ids = [aws_security_group.k3s_server.id]
  instance_type          = "t3.medium"
  user_data = base64encode(templatefile("${path.module}/server-userdata.tmpl", {   #you write here your tmpl file name
    token = random_password.k3s_cluster_secret.result,                             #here we create token randomly
  }))

  tags = {
    Name = "${local.name}-kube-master"
  }
}

resource "aws_instance" "worker" {
  ami                    = "ami-04505e74c0741db8d"
  count                  = 2
  key_name               = var.key_name
  #key_name               = "serkey"
  vpc_security_group_ids = [aws_security_group.k3s_agent.id]
  instance_type = "t3.medium"
  user_data = base64encode(templatefile("${path.module}/agent-userdata.tmpl", {
    host  = aws_instance.master.private_ip,
    token = random_password.k3s_cluster_secret.result
  }))
  tags = {
    Name = "${local.name}-kube-worker"
  }
}


output "masters_public_ip" {
  value = aws_instance.master.public_ip
}
