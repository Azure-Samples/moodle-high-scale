#!/bin/bash

envsubst < /var/www/html/config.php.template > /var/www/html/config.php
chown www-data:www-data /var/www/html/config.php

mkdir /var/www/localdata/cache /var/www/localdata/request
php /var/www/html/admin/cli/alternative_component_cache.php --rebuild
chown -R www-data:www-data /var/www/localdata

php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=enabletasks --set=1
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=deletelocal --set=1
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=consistencydelay --set=0
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=sizethreshold --set=0
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=minimumage --set=0
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=azure_accountname --set="$STG_NAME"
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=azure_container --set="$STG_CONTAINER_NAME"
php /var/www/html/admin/cli/cfg.php --component=tool_objectfs --name=azure_sastoken --set="$STG_SAS_TOKEN"

nginx -g 'daemon off;' &
php-fpm8.1 --nodaemonize &  

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
