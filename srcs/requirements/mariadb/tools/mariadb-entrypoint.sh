#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE must be set}"
: "${MYSQL_USER:?MYSQL_USER must be set}"

case "$MYSQL_DATABASE" in
    ''|*[!a-zA-Z0-9_]*)
        printf '%s\n' "MYSQL_DATABASE may contain only letters, numbers, and underscores" >&2
        exit 1
        ;;
esac

case "$MYSQL_USER" in
    ''|*[!a-zA-Z0-9_]*)
        printf '%s\n' "MYSQL_USER may contain only letters, numbers, and underscores" >&2
        exit 1
        ;;
esac

if [ "${#MYSQL_DATABASE}" -gt 64 ] || [ "${#MYSQL_USER}" -gt 32 ]; then
    printf '%s\n' "MYSQL_DATABASE or MYSQL_USER is too long" >&2
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

DB_ROOT_PASSWORD=$(read_secret /run/secrets/db_root_password)
DB_PASSWORD=$(read_secret /run/secrets/db_password)

sql_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/''/g"
}

ROOT_PASSWORD_SQL=$(sql_escape "$DB_ROOT_PASSWORD")
DB_PASSWORD_SQL=$(sql_escape "$DB_PASSWORD")

umask 077
mkdir -p /run/mysqld /var/lib/mysql
chown mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        --skip-test-db
fi

INIT_FILE=/run/mariadb-init.sql

{
    printf "ALTER USER 'root'@'localhost' IDENTIFIED BY '%s';\n" "$ROOT_PASSWORD_SQL"
    printf 'CREATE DATABASE IF NOT EXISTS `%s`;\n' "$MYSQL_DATABASE"
    printf "CREATE USER IF NOT EXISTS '%s'@'%%' IDENTIFIED BY '%s';\n" "$MYSQL_USER" "$DB_PASSWORD_SQL"
    printf "ALTER USER '%s'@'%%' IDENTIFIED BY '%s';\n" "$MYSQL_USER" "$DB_PASSWORD_SQL"
    printf "GRANT ALL PRIVILEGES ON \`%s\`.* TO '%s'@'%%';\n" "$MYSQL_DATABASE" "$MYSQL_USER"
} > "$INIT_FILE"

chown mysql:mysql "$INIT_FILE"
chmod 600 "$INIT_FILE"

exec "$@"