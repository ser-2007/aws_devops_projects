#! /bin/bash
yum update -y
yum install python3 -y
pip3 install flask
pip3 install flask_mysql
yum install git -y
TOKEN="xxxxxxxxxxxxxxx" #write your own token for thi project
cd /home/ec2-user && git clone https://$TOKEN@github.com/ser-2007/aws_devops_projects/tree/main/DEVOPS/202-Terraform-Phonebook-Application-deployed-on-AWS.git
python3 /home/ec2-user/phonebook/phonebook-app.py