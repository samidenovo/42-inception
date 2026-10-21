FROM debian:bookworm

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY tools/mariadb-entrypoint.sh /usr/local/bin/mariadb-entrypoint

RUN chmod 755 /usr/local/bin/mariadb-entrypoint

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint"]

CMD ["mariadbd", "--user=mysql", "--bind-address=0.0.0.0"]
