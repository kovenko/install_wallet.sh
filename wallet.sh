#!/bin/bash

output() {
  printf "\E[0;33;40m"
  echo $1
  printf "\E[0m"
}

clear

# Исходные данные
time="Europe/Moscow"
email="v320@mail.ru"
server_name="a.trittium.cc"

output "Make sure you double check before hitting enter! Only one shot at these!"
#read -e -p "Enter time zone (e.g. America/New_York) : " time
#read -e -p "Server name (no http:// or www. just example.com) : " server_name
#read -e -p "Enter support email (e.g. admin@example.com) : " email
output "==================================================="
output ""
output ""

output "Updating system and installing required packages."
#apt-get -y update
#apt-get -y upgrade
#apt-get -y dist-upgrade
#apt-get -y autoremove
output "==================================================="
output ""
output ""

output "Install MySQL"
#apt-get -y install mysql-server
output "Create DataBase wallet"
#mysql -uroot -p -e "create database wallet"
output "==================================================="
output ""
output ""

output "Install Nginx"
#apt-get -y install nginx
#rm /etc/nginx/sites-enabled/default
output "==================================================="
output ""
output ""

output "Installing php7.x and other needed files"
#apt-get -y install php7.0-fpm php7.0 php7.0-common php7.0-opcache php7.0-gd php7.0-mysql
#apt-get -y install php7.0-imap php7.0-cli php7.0-cgi php-pear php-auth-sasl php7.0-mcrypt
#apt-get -y install mcrypt imagemagick libruby php7.0-curl php7.0-intl php7.0-pspell
#apt-get -y install php7.0-recode php7.0-sqlite3 php7.0-tidy php7.0-xmlrpc php7.0-xsl
#apt-get -y install memcached php-memcache php-imagick php-gettext php7.0-zip php7.0-mbstring
#phpenmod mcrypt
#phpenmod mbstring
output "==================================================="
output ""
output ""

output "Update UFW rules for Nginx"
#ufw allow http
#ufw allow https
output "==================================================="
output ""
output ""

output "Configuration Nginx"
echo '
server {
  listen 80;
  listen [::]:80;
  server_name '"${server_name}"';
  root "/var/www/'"${server_name}"'";
  index index.html index.php;
  charset utf-8;
  access_log /var/log/nginx/'"${server_name}"'.access.log;
  error_log  /var/log/nginx/'"${server_name}"'.error.log error;
  # allow larger file uploads and longer script runtimes
  client_body_buffer_size  50k;
  client_header_buffer_size 50k;
  client_max_body_size 50k;
  large_client_header_buffers 2 50k;
  sendfile off;
  # strengthen ssl security
  # Add headers to serve security related headers
  add_header Strict-Transport-Security "max-age=15768000; preload;";
  add_header X-Content-Type-Options nosniff;
  add_header X-XSS-Protection "1; mode=block";
  add_header X-Robots-Tag none;
  add_header Content-Security-Policy "frame-ancestors 'self'";
  location = /favicon.ico { access_log off; log_not_found off; }
  location = /robots.txt  { access_log off; log_not_found off; }
  location /myadmin {
    alias /usr/share/phpmyadmin;
    index index.php;
    location ~ ^/myadmin/(.+.php)$ {
      alias /usr/share/phpmyadmin/$1;
      fastcgi_pass unix:/run/php/php7.0-fpm.sock;
      include fastcgi_params;
      fastcgi_index index.php;
      fastcgi_param SCRIPT_FILENAME /usr/share/phpmyadmin/$1;
    }
    location ~* ^/myadmin/(.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
      alias /usr/share/phpmyadmin/$1;
    }
  }
  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
    fastcgi_intercept_errors off;
    fastcgi_buffer_size 16k;
    fastcgi_buffers 4 16k;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    try_files $uri $uri/ =404;
  }
  location ~ \.php$ {
    return 404;
  }
  location ~ \.sh {
    return 404;
  }
  location ~ /\.ht {
    deny all;
  }
  location ~ /.well-known {
    allow all;
  }
}
' | tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1
#ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
#mkdir "/var/www/${server_name}"
echo '<h1>You see test_index.php</h1>' > "/var/www/${server_name}/test_index.php"
chown -R www-data:www-data "/var/www/${server_name}"
output "Create browser url: http://${server_name} for test"
service nginx restart
output "==================================================="
output ""
output ""

output "Install LetsEncrypt"
#apt-get -y install letsencrypt
#wget https://dl.eff.org/certbot-auto && chmod a+x certbot-auto
#mv certbot-auto /etc/letsencrypt/
output "Certificat renew cron"
#crontab -l | { cat; echo "#45 5 * * 6 cd /etc/letsencrypt/ && ./certbot-auto renew && /etc/init.d/nginx restart"; } | crontab -
output "==================================================="
output ""
output ""

output "Install certificat"
#letsencrypt certonly -a webroot --webroot-path="/var/www/${server_name}" --email "$email" --agree-tos -d "$server_name"
#openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sed -i 's/listen 80;/listen 443 ssl http2;/' /etc/nginx/sites-available/$server_name.conf
sed -i 's/listen \[::\]:80;/listen [::]:443 ssl http2;/' /etc/nginx/sites-available/$server_name.conf
SERVER=`echo 'server {\n\
  listen 80;\n\
  listen [::]:80;\n\
  server_name '"${server_name}"';\n\
  return 301 https:\/\/'"$server_name"'$request_uri;\n\
}\n\
\n\
server {
'`
sed -i "s/server {/$SERVER/" /etc/nginx/sites-available/$server_name.conf
SSL=`echo "# strengthen ssl security\n\
  ssl_certificate \/etc\/letsencrypt\/live\/${server_name}\/fullchain.pem;\n\
  ssl_certificate_key \/etc\/letsencrypt\/live\/${server_name}\/privkey.pem;\n\
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;\n\
  ssl_prefer_server_ciphers on;\n\
  ssl_session_cache shared:SSL:10m;\n\
  ssl_ciphers \"EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4\";\n\
  ssl_dhparam \/etc\/ssl\/certs\/dhparam\.pem;
"`
sed -i "s/# strengthen ssl security/$SSL/" /etc/nginx/sites-available/$server_name.conf
service nginx restart
output "Create browser url: http://${server_name} for test. You need redirect to https."
output "==================================================="
output ""
output ""

output "Install phpMyAdmin"
#apt-get -y install phpmyadmin
output "==================================================="
output ""
output ""

output "Update default timezone."
# check if link file
[ -L /etc/localtime ] &&  unlink /etc/localtime
# update time zone
ln -sf /usr/share/zoneinfo/$time /etc/localtime
aptitude -y install ntpdate
# write time to clock.
hwclock -w
output "==================================================="
output ""
output ""
output "END"
