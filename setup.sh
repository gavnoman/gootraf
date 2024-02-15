#!/bin/bash

# Отключаем запись истории команд в bash
unset HISTFILE
echo 'unset HISTFILE' >> /etc/bashrc
rm -f ~/.bash_history

# Останавливаем и отключаем rsyslog
systemctl stop rsyslog && systemctl disable rsyslog

# Обновляем список пакетов и устанавливаем необходимые пакеты
apt-get update
apt-get install -y nginx ufw

# Запускаем и включаем Nginx
systemctl start nginx
systemctl enable nginx

# Разрешаем доступ к Nginx
ufw allow 'Nginx Full'

# Удаляем конфигурации по умолчанию
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

# Запрашиваем IP-адрес фронтенда и домены
read -p "IP фронтенда и домены: " ip_domains

ip=$(echo $ip_domains | awk '{print $1}')
domains=$(echo $ip_domains | awk '{print $2}')

# Проверяем, был ли введен домен
if [ -z "$domains" ]; then
    echo "Ошибка: Не указаны домены."
    exit 1
fi

# Запрашиваем IP-адрес бэкенда
read -p "IP бэкенда: " proxy_ip

# Создаем конфигурационный файл Nginx
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

# Создаем символическую ссылку на конфигурацию в sites-enabled
ln -s "/etc/nginx/sites-available/$ip" "/etc/nginx/sites-enabled/$ip"

# Перезапускаем Nginx
systemctl restart nginx

# Запрашиваем email для сертификата Let's Encrypt
read -p "Введите ваш email: " email

# Запрашиваем дополнительные домены для сертификата
cert_domains="$domains"
while true; do
    read -p "Добавьте еще один домен для сертификата (оставьте пустым для завершения): " additional_domain
    if [ -z "$additional_domain" ]; then
        break
    fi
    cert_domains="$cert_domains,$additional_domain"
done

# Устанавливаем и настраиваем сертификат Let's Encrypt
apt install -y certbot python3-certbot-nginx
certbot --nginx -d "$cert_domains" --non-interactive --agree-tos --email "$email"
