FROM alpine:3.6
MAINTAINER Pierre GINDRAUD <pgindraud@gmail.com>

ENV PHPPGADMIN_VERSION=5.1 \
    POSTGRES_NAME=PostgreSQL \
    POSTGRES_HOST=localhost \
    POSTGRES_PORT=5432 \
    POSTGRES_DEFAULTDB=template1 \
    PHPPGADMIN_LOGIN_SECURITY=1 \
    PHPPGADMIN_OWNED_ONLY=0 \
    PHPPGADMIN_SHOW_COMMENTS=1 \
    PHPPGADMIN_SHOW_ADVANCED=0 \
    PHPPGADMIN_SHOW_SYSTEM=0 \
    PHPPGADMIN_SHOW_OIDS=0 \
    PHPPGADMIN_USE_XHTML_STRICT=0 \
    PHPPGADMIN_THEME=default \
    PHPPGADMIN_PLUGINS=""

# Install dependencies
RUN apk --no-cache add \
    curl \
    nginx \
    php5 \
    php5-fpm \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    php5-pgsql \
    postgresql \
    supervisor \
    tar && \
    mkdir -p /run/nginx && \
    mkdir -p /var/www /data/data && \
    cd /var/www && \
    curl -O -L "http://downloads.sourceforge.net/project/phppgadmin/phpPgAdmin%20%5Bstable%5D/phpPgAdmin-${PHPPGADMIN_VERSION}/phpPgAdmin-${PHPPGADMIN_VERSION}.tar.gz" && \
    tar -xzf "phpPgAdmin-${PHPPGADMIN_VERSION}.tar.gz" --strip 1 && \
    rm "phpPgAdmin-${PHPPGADMIN_VERSION}.tar.gz" && \
    rm -rf conf/config.inc.php-dist LICENSE CREDITS DEVELOPERS FAQ HISTORY INSTALL TODO TRANSLATORS && \
    sed -i 's|$cmd = $exe . " -i";|$cmd = $exe;|' /var/www/dbexport.php && \
    apk --no-cache del curl tar

# Add some configurations files
COPY root/ /
COPY config.inc.php /var/www/conf/

ENV MAX_UPLOAD_SIZE=2048

# Apply PHP FPM configuration
RUN sed -i -e "s|;clear_env\s*=\s*no|clear_env = no|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php5/php-fpm.conf && \
    echo "php_admin_value[display_errors] = 'stderr'" >> /etc/php5/php-fpm.conf && \
    sed -i -e "s|listen\s*=\s*127\.0\.0\.1:9000|listen = /var/run/php-fpm5.sock|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.owner\s*=\s*|listen.owner = |g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.group\s*=.*$|listen.group = nginx|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.mode\s*=\s*|listen.mode = |g" /etc/php5/php-fpm.conf && \
    echo "upload_max_filesize = ${MAX_UPLOAD_SIZE}M" >> /etc/php5/php.ini && \
    echo "post_max_size = ${MAX_UPLOAD_SIZE}M" >> /etc/php5/php.ini && \
    chown -R nobody /var/www

# Apply nginx configuration
RUN sed -i -e "s|client_max_body_size\s*2M;|client_max_body_size ${MAX_UPLOAD_SIZE}M;|g" /etc/nginx/nginx.conf

EXPOSE 80
WORKDIR /var/www

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
