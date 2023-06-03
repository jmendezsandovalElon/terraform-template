#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World from $(hostname -f)" | sudo tee /var/www/html/index.html