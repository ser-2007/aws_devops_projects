#! /bin/bash
sudo su
yum -y install httpd
echo "<p> Hello World- This is Serkan's Firt DevOps project- Wellcome  </p>" >> /var/www/html/index.html
sudo systemctl enable httpd
sudo systemctl start httpd