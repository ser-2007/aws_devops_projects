//This terraform file deploys Phonebook Application to five Docker Machines on EC2 Instances  which are ready for Docker Swarm operations. Docker Machines will run on Amazon Linux 2  with custom security group allowing SSH (22), HTTP (80) UDP (4789, 7946),  and TCP(2377, 7946, 8080) connections from anywhere.
//User needs to select appropriate key name when launching the template.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  //  access_key = " "
  //  secret_key = " "
  //  If you have entered your credentials in AWS CLI before, you do not need to use these arguments.
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  name = "us-east-1"
}

data "template_file" "leader-master" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Leader-Manager
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    yum install git -y
    docker swarm init
    docker service create \
      --name=viz \
      --publish=8080:8080/tcp \
      --constraint=node.role==manager \
      --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      dockersamples/visualizer
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    yum install amazon-ecr-credential-helper -y
    mkdir -p /home/ec2-user/.docker
    cd /home/ec2-user/.docker
    echo '{"credsStore": "ecr-login"}' > config.json
  EOF
}
data "template_file" "manager" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Manager
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    yum install python3 -y
    amazon-linux-extras install epel -y
    yum install python-pip -y
    pip install ec2instanceconnectcli
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
    --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token manager | grep -i 'docker')"
    yum install amazon-ecr-credential-helper -y
    mkdir -p /home/ec2-user/.docker
    cd /home/ec2-user/.docker
    echo '{"credsStore": "ecr-login"}' > config.json
  EOF
}
data "template_file" "worker" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Worker
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    yum install python3 -y
    amazon-linux-extras install epel -y
    yum install python-pip -y
    pip install ec2instanceconnectcli
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
     --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token worker | grep -i 'docker')"
    yum install amazon-ecr-credential-helper -y
    mkdir -p /home/ec2-user/.docker
    cd /home/ec2-user/.docker
    echo '{"credsStore": "ecr-login"}' > config.json
  EOF
}

resource "aws_iam_instance_profile" "ec2ecr-profile" {
  name = "serkanswarmprofile"
  role = aws_iam_role.ec2fulltoecr.name
}

resource "aws_iam_role" "ec2fulltoecr" {
  name = "serkanec2roletoecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ec2-user"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }
      managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}

resource "aws_instance" "docker-machine-leader-manager" {
  ami             = "ami-0a8b4cd432b1c3063"
  instance_type   = "t2.medium"
  key_name        = "ec2_key" #write your own key
  root_block_device {
      volume_size = 16
  }  
  //  Write your pem file name
  security_groups = ["serkan-docker-swarm-sec-gr"]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  user_data = data.template_file.leader-master.rendered
  tags = {
    Name = "serkan-Docker-Swarm-Leader-Manager"
    server = "docker-grand-master"
    project = "205"
  }
}

resource "aws_instance" "docker-machine-managers" {
  ami             = "ami-0a8b4cd432b1c3063"
  instance_type   = "t2.micro"
  key_name        = "ec2_key"
  //  Write your pem file name
  security_groups = ["serkan-docker-swarm-sec-gr"]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  count = 2
  user_data = data.template_file.manager.rendered
  tags = {
    Name = "serkan-Docker-Swarm-Manager-${count.index + 1}"
    server = "docker-manager-${count.index + 2}"
    project = "205"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}

resource "aws_instance" "docker-machine-workers" {
  ami             = "ami-0a8b4cd432b1c3063"
  instance_type   = "t2.micro"
  key_name        = "ec2_key"
  //  Write your pem file name
  security_groups = ["serkan-docker-swarm-sec-gr"]
  iam_instance_profile = aws_iam_instance_profile.ec2ecr-profile.name
  count = 2
  user_data = data.template_file.worker.rendered
  tags = {
    Name = "serkan-Docker-Swarm-Worker-${count.index + 1}"
    server = "docker-worker-${count.index + 1}"
    project = "205"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}


variable "sg-ports" {
  default = [80, 22, 2377, 7946, 8080]
}
resource "aws_security_group" "tf-docker-sec-gr" {
  name = "serkan-docker-swarm-sec-gr"
  tags = {
    Name = "swarm-sec-gr"
  }
  dynamic "ingress" {
    for_each = var.sg-ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
    from_port = 7946
    protocol = "udp"
    to_port = 7946
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 4789
    protocol = "udp"
    to_port = 4789
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "leader-manager-public-ip" {
  value = aws_instance.docker-machine-leader-manager.public_ip 
}

output "website-url" {
  value = "http://${aws_instance.docker-machine-leader-manager.public_ip}"
}

output "viz-url" {
  value = "http://${aws_instance.docker-machine-leader-manager.public_ip}:8080"
}

output "manager-public-ip" {
  value = aws_instance.docker-machine-managers.*.public_ip 
}

output "worker-public-ip" {
  value = aws_instance.docker-machine-workers.*.public_ip 
}