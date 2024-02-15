#!/usr/bin/env python
# Вариант установки 1 chmode +x setup.sh; ./setup.sh далее в консоли вбить данные
# Вариант установки 2 wget -O - https://raw.githubusercontent.com/gavnoman/gootraf/main/setup.sh | bash -s -- "IP1 DOMAIN" "PROXY_IP" "your.email@example.com"
# IP1 DOMAIN - IP-адрес фронтенда и домен, разделенные пробелом.
# PROXY_IP - IP-адрес бэкенда.
# your.email@example.com - мыло от балды.

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
domains=$(echo $ip_domains | awk '{print $2, $3}')

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

ln -s "/etc/nginx/sites-available/$ip" "/etc/nginx/sites-enabled/"

systemctl restart nginx

read -p "Enter your email: " email

apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d "$domains" --non-interactive --agree-tos --email "$email"
