#!/bin/bash

dnf install -y httpd 

echo "My ALB Web Page" > /var/www/html/index.html
systemctl restart httpd 
systemctl enable httpd 
