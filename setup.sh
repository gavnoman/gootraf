#!/bin/bash

unset HISTFILE
echo 'unset HISTFILE' >> /etc/bashrc
rm -f ~/.bash_history
systemctl stop rsyslog && systemctl disable rsyslog
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
apt-get install -y ufw
ufw allow 'Nginx Full'
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

read -p "IP frontend and domains: " ip_domains

ip=$(echo $ip_domains | awk '{print $1}')
domains=$(echo $ip_domains | awk '{print $2}')

read -p "IP backend: " proxy_ip

cat << EOF > "/etc/nginx/sites-available/$ip"
server {
  server_name $domains;

  root /var/www/html;
  index index.php index.html index.nginx-debian.html;
  access_log  /dev/null;
  error_log /dev/null;

  location / {
    proxy_pass http://$proxy_ip/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s "/etc/nginx/sites-available/$ip" "/etc/nginx/sites-enabled/$ip"

systemctl restart nginx

read -p "Enter your email: " email

cert_domains="$domains"
while true; do
    read -p "Add another domain for certificate (leave empty to finish): " additional_domain
    if [ -z "$additional_domain" ]; then
        break
    fi
    cert_domains="$cert_domains,$additional_domain"
done

apt install -y certbot python3-certbot-nginx
certbot --nginx -d "$cert_domains" --non-interactive --agree-tos --email "$email"

