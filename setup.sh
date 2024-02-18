#!/usr/bin/env bash
# Установка: Перед запуском скрипта, прописать А запись в панельке регера доменов.
# 1) wget https://raw.githubusercontent.com/gavnoman/gootraf/main/setup.sh
# 2) chmod +x setup.sh; ./setup.sh
# далее в консоли вбить данные
# IP frontend and domains: через пробел, пример 111.111.111.111 domain.com
# IP backend: ип бэкенда
# Enter your email: мыло от балды

apt-get purge -y rsyslog
systemctl stop systemd-journald
rm /var/log/*.log
rm -f ~/.bash_history
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

ln -s "/etc/nginx/sites-available/$ip" "/etc/nginx/sites-enabled/$ip"

systemctl restart nginx

read -p "Enter your email: " email

apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d "$domains" --non-interactive --agree-tos --email "$email"

rm setup.sh
