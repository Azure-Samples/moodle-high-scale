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

#php /var/www/html/admin/cli/scheduled_task.php --execute='\tool_objectfs\task\check_objects_location'
#php /var/www/html/admin/cli/scheduled_task.php --execute='\tool_objectfs\task\push_objects_to_storage'
#php /var/www/html/admin/cli/scheduled_task.php --execute='\tool_objectfs\task\delete_local_objects'
#php /var/www/html/admin/cli/scheduled_task.php --execute='\tool_objectfs\task\generate_status_report'

echo '* * * * * www-data php /var/www/html/admin/cli/cron.php  > /proc/1/fd/1 2>/proc/1/fd/2' >> /etc/crontab
cron -f &
 
# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?