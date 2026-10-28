FROM debian:bookworm

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        mariadb-client \
        php8.2-cli \
        php8.2-curl \
        php8.2-fpm \
        php8.2-gd \
        php8.2-intl \
        php8.2-mbstring \
        php8.2-mysql \
        php8.2-xml \
        php8.2-zip \
        unzip \
        util-linux \
    && curl --fail --location --silent --show-error \
        --output /usr/local/bin/wp \
        https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar \
    && printf '%s  %s\n' \
        'ce34ddd838f7351d6759068d09793f26755463b4a4610a5a5c0a97b68220d85c' \
        '/usr/local/bin/wp' \
        | sha256sum --check - \
    && chmod 755 /usr/local/bin/wp \
    && curl --fail --location --silent --show-error \
        --output /tmp/wordpress.zip \
        https://downloads.wordpress.org/release/wordpress-7.1.3.zip \
    && unzip -q /tmp/wordpress.zip -d /tmp \
    && mkdir -p /usr/src/wordpress \
    && cp -a /tmp/wordpress/. /usr/src/wordpress/ \
    && rm -rf /tmp/wordpress /tmp/wordpress.zip /var/lib/apt/lists/*

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/wordpress-entrypoint.sh /usr/local/bin/wordpress-entrypoint

RUN chmod 755 /usr/local/bin/wordpress-entrypoint

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint"]
CMD ["php-fpm8.2", "--nodaemonize"]
