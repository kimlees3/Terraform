#!/bin/bash

dnf install -y httpd 
cat <<EOF > /var/www/html/index.html
<h1>db IP: ${dbaddress}</h1>
<h1>db Port: ${dbport}</h1>
<h1>db name: ${dbname}</h1>
EOF
systemctl enable --now httpd 
