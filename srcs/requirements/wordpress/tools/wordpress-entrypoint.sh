#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME must be set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE must be set}"
: "${MYSQL_USER:?MYSQL_USER must be set}"
: "${WP_TITLE:?WP_TITLE must be set}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER must be set}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL must be set}"
: "${WP_USER:?WP_USER must be set}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL must be set}"

ADMIN_USER_LOWER=$(printf '%s' "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')

case "$ADMIN_USER_LOWER" in
    *admin*)
        printf '%s\n' "WP_ADMIN_USER must not contain 'admin'." >&2
        exit 1
        ;;
esac

if [ "$WP_ADMIN_USER" = "$WP_USER" ]; then
    printf '%s\n' "WP_ADMIN_USER and WP_USER must be different." >&2
    exit 1
fi

read_secret() {
    secret_path=$1

    if [ ! -r "$secret_path" ]; then
        printf 'Cannot read required secret file: %s\n' "$secret_path" >&2
        return 1
    fi

    secret_value=$(cat "$secret_path")

    if [ -z "$secret_value" ]; then
        printf 'Secret file is empty: %s\n' "$secret_path" >&2
        return 1
    fi

    case "$secret_value" in
        *'
'*)
            printf 'Secret must be a single line: %s\n' "$secret_path" >&2
            return 1
            ;;
    esac

    printf '%s' "$secret_value"
}

DB_PASSWORD=$(read_secret /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(read_secret /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(read_secret /run/secrets/wp_user_password)

if [ ! -f /var/www/html/wp-includes/version.php ]; then
    if [ -n "$(find /var/www/html -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        printf '%s\n' \
            "WordPress directory is not empty but does not contain WordPress core files." \
            >&2
        exit 1
    fi

    cp -a /usr/src/wordpress/. /var/www/html/
    chown -R www-data:www-data /var/www/html
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    printf '%s\n' "$DB_PASSWORD" |
        runuser -u www-data -- wp config create \
            --dbname="$MYSQL_DATABASE" \
            --dbuser="$MYSQL_USER" \
            --dbhost=mariadb:3306 \
            --prompt=dbpass \
            --skip-check \
            --path=/var/www/html
fi

chmod 640 /var/www/html/wp-config.php

attempt=1

while [ "$attempt" -le 30 ]; do
    if [ "$attempt" -lt 30 ]; then
        if runuser -u www-data -- wp db check \
            --path=/var/www/html >/dev/null 2>&1; then
            break
        fi
    else
        if ! runuser -u www-data -- wp db check --path=/var/www/html; then
            printf '%s\n' "MariaDB did not become available to WordPress after 30 attempts." >&2
            exit 1
        fi
    fi

    sleep 2
    attempt=$((attempt + 1))
done

if ! runuser -u www-data -- wp core is-installed \
    --path=/var/www/html >/dev/null 2>&1; then
    printf '%s\n' "$WP_ADMIN_PASSWORD" |
        runuser -u www-data -- wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="$WP_TITLE" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --prompt=admin_password \
            --skip-email \
            --path=/var/www/html
fi

if ! runuser -u www-data -- wp user get "$WP_USER" \
    --field=ID \
    --path=/var/www/html >/dev/null 2>&1; then
    printf '%s\n' "$WP_USER_PASSWORD" |
        runuser -u www-data -- wp user create \
            "$WP_USER" \
            "$WP_USER_EMAIL" \
            --role=subscriber \
            --prompt=user_pass \
            --path=/var/www/html
fi

exec "$@"
