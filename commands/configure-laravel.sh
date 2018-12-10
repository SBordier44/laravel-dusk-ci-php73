#!/bin/bash
cd ${CI_PROJECT_DIR}
chgrp -R www-data *
chmod -R ug+rwx storage bootstrap/cache
php artisan view:clear
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan key:generate
