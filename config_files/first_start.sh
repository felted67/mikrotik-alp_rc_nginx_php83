#!/bin/ash
adduser -D -g 'www' www
mkdir /www
chown -R www:www /var/lib/nginx
chown -R www:www /www
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
mv /etc/nginx/nginx.new.conf /etc/nginx/nginx.conf
mv /etc/php81/php-fpm.conf /etc/php81/php-fpm.conf.orig
mv /etc/php81/php-fpm.new.conf /etc/php81/php-fpm.conf
mv /etc/php81/php-fpm.d/www.conf /etc/php81/php-fpm.d/www.conf.orig
mv /etc/php81/php-fpm.d/www.new.conf /etc/php81/php-fpm.d/www.conf
mv /root/index.html /www/
mv /root/index.php /www/
mv /root/phpinfo.php /www/
chown www:www /www/index.html
chown www:www /www/index.php
chown www:www /www/phpinfo.php
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
/sbin/php_configure.sh
rc-update add sshd 
rc-update add php-fpm81
rc-update add nginx
rc-service sshd start
rc-service php-fpm81 start
rc-service nginx start
echo "****"
echo "'"
echo "Don't forget to set root-ssh password !!!"
echo "*"
echo "****"
echo "*"
echo "first_start.sh completed !"
echo "*"
echo "****"
rc-update del auto_init