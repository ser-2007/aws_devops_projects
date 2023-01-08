terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}   # Account ID, ARN and USERID 

data "aws_region" "current" {} # Gives current region

variable "key-name" {
  default = "serkey"   # We will pu our key name without .PEM 
}

variable "kubeconfig_mode" {
 default = "644"
}

variable "template_file" {
 default = "644"
}

locals {
  name = "K3S"   # change here, optional 
 }

resource "aws_instance" "master" {
  ami                  = "ami-0a6b2839d44d781b2"
  instance_type        = "t3.medium"
  key_name             = var.key-name
  # iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name  IF WE NEED WE CAN USE IT"
  vpc_security_group_ids = [ aws_security_group.tf-k3s-master-sec-gr.id ]
  user_data            = <<EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install curl
  sudo hostnamectl set-hostname k3s-master && bash
  sudo curl -sfL https://get.k3s.io | sh -
  
  EOF
#"${file("master.sh")}" #file("master.sh") 
  tags = {
    Name = "${local.name}-kube-master"
  }
}

resource "aws_instance" "worker" {
  ami                  = "ami-0a6b2839d44d781b2"
  instance_type        = "t3.medium"
  key_name             = var.key-name
  # iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  vpc_security_group_ids = [ aws_security_group.tf-k3s-master-sec-gr.id ]
  user_data            = <<EOF
  #!/bin/bash
  sudo hostnamectl set-hostname K3S-worker-1 && bash
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install curl
  sudo curl -sfL https://get.k3s.io | K3S_URL=https://$"{aws_instance.master.private_ip}":6443 K3S_TOKEN=$"{token}" sh -
  EOF
     #"${file("worker.sh")}"  #file("worker.sh")  # to get data from the files
  tags = {
    Name = "${local.name}-kube-worker"
  }
  depends_on = [aws_instance.master]
}

# data "template_file" "worker" {
#   template = 
  # vars = {
  #   region = data.aws_region.current.name
  #   master-id = aws_instance.master.id
  #   master-private = aws_instance.master.private_ip
  # }

#}

# data "template_file" "master" {
#   template = file("master.sh")
# }

resource "aws_security_group" "tf-k3s-master-sec-gr" {
  name = "${local.name}-k3s-master-sec-gr"
  tags = {
    Name = "${local.name}-k3s-master-sec-gr"
  }

  # ingress {
  #  from_port = 0
  # protocol  = "-1"
  #  to_port   = 0
  #  self = true
  # }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "master_public_dns" {
  value = aws_instance.master.public_dns
}

output "master_private_dns" {
  value = aws_instance.master.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker.private_dns
}