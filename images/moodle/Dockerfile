FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y locales locales-all && \
    echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen    

ENV LC_ALL pt_BR.UTF-8
ENV LANG pt_BR.UTF-8
ENV LANGUAGE pt_BR.UTF-8

RUN apt-get install -y tzdata && \
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime 

RUN apt-get install -y software-properties-common unzip cron && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get install -y gettext wget nginx-full php8.1 php8.1-fpm php8.1-common \
    php8.1-mbstring php8.1-xmlrpc php8.1-soap php8.1-gd php8.1-xml \
    php8.1-intl php8.1-pgsql php8.1-cli php8.1-mcrypt php8.1-ldap \
    php8.1-zip php8.1-curl php8.1-redis php8.1-opcache php8.1-igbinary \
    php8.1-pspell php8.1-imagick php8.1-imap php8.1-apcu php8.1-bz2 \
    php8.1-yaml php8.1-bcmath poppler-utils ffmpeg gpac \
    graphviz aspell aspell-pt-br ghostscript texlive texlive

RUN wget -q https://github.com/moodle/moodle/archive/refs/heads/MOODLE_402_STABLE.zip && \
    unzip -q MOODLE_402_STABLE.zip && \
    mv moodle-MOODLE_402_STABLE/* /var/www/html/ && \
    rm -rf master.zip moodle-MOODLE_402_STABLE /var/www/html/.github /var/www/html/.grunt

COPY --chown=www-data:www-data files/config.php /var/www/html/config.php.template

#install objectfs plugin
RUN wget -q https://github.com/catalyst/moodle-tool_objectfs/archive/refs/heads/MOODLE_310_STABLE.zip && \
    wget -q https://github.com/catalyst/moodle-local_azure_storage/archive/refs/heads/master.zip && \
    unzip -q MOODLE_310_STABLE.zip && \
    unzip -q master.zip && \
    mkdir /var/www/html/admin/tool/objectfs/ && \
    mkdir /var/www/html/local/azure_storage && \
    mv moodle-tool_objectfs-MOODLE_310_STABLE/* /var/www/html/admin/tool/objectfs/ && \
    mv moodle-local_azure_storage-master/* /var/www/html/local/azure_storage && \
    rm -rf master.zip MOODLE_310_STABLE.zip moodle-tool_objectfs-MOODLE_310_STABLE moodle-local_azure_storage-master

#install Bulk Enrolment plugin
RUN wget -q https://moodle.org/plugins/download.php/29087/local_bulkenrol_moodle41_2023010500.zip && \
    unzip -q local_bulkenrol_moodle41_2023010500.zip && \
    mv bulkenrol /var/www/html/local && \
    rm -rf local_bulkenrol_moodle41_2023010500.zip

#install rediscluster plugin
RUN wget -q https://codeload.github.com/open-lms-open-source/moodle-cachestore_rediscluster/zip/refs/heads/main -O rediscluster.zip && \
    unzip -q rediscluster.zip && \
    mv moodle-cachestore_rediscluster-main /var/www/html/cache/stores/rediscluster && \
    rm -rf rediscluster.zip

#install forcedcache plugin
RUN wget -q https://codeload.github.com/catalyst/moodle-tool_forcedcache/zip/refs/heads/MOODLE_40_STABLE -O forcedcache.zip && \
    unzip -q forcedcache.zip && \
    mv moodle-tool_forcedcache-MOODLE_40_STABLE /var/www/html/admin/tool/forcedcache && \
    rm -rf forcedcache.zip

#install heartbeat plugin
RUN wget -q https://moodle.org/plugins/download.php/16046/tool_heartbeat_moodle38_2018012300.zip && \
    unzip -q tool_heartbeat_moodle38_2018012300.zip && \
    mv heartbeat /var/www/html/admin/tool/ && \
    rm -rf tool_heartbeat_moodle38_2018012300.zip
    

COPY files/lib.php /var/www/html/cache/stores/rediscluster/lib.php
COPY files/session.php /var/www/html/cache/stores/rediscluster/classes/session.php

RUN mkdir -p /var/www/localdata/cache && \
    chown -R www-data:www-data /var/www/localdata/

RUN chown -R www-data:www-data /var/www/html/

RUN rm -rf /etc/nginx/sites-enabled/default && \
    mkdir /var/run/php && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stderr /var/log/php8.1-fpm.log

COPY files/nginx-moodle.conf /etc/nginx/sites-enabled/moodle.conf
COPY files/nginx.conf /etc/nginx/nginx.conf

COPY files/php.ini /etc/php/8.1/fpm/php.ini
COPY files/php.ini /etc/php/8.1/cli/php.ini

COPY files/init.sh init.sh
COPY files/init_cron.sh init_cron.sh
COPY files/www.conf /etc/php/8.1/fpm/pool.d/www.conf
COPY files/opcache.ini /etc/php/8.1/mods-available/opcache.ini
COPY files/apcu.ini /etc/php/8.1/mods-available/apcu.ini

RUN chmod +x init.sh
RUN chmod +x init_cron.sh

CMD ./init.sh