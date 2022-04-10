FROM nginx:stable-alpine

LABEL maintainer="rudi2e"
LABEL title="nginx"
LABEL version="0.1.2"
LABEL description=""

RUN ([ -x "/usr/bin/run-parts" ] || ln -s /bin/run-parts /usr/bin/run-parts) \
    && apk add --no-cache supervisor logrotate jq curl ca-certificates \
    && rm -rf /var/cache/apk/* \
    && update-ca-certificates \
    && ([ -d "/usr/local/sbin" ] || mkdir /usr/local/sbin) \
    && curl -L "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker" -o /usr/local/sbin/install-ngxblocker \
    && curl -L "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/update-ngxblocker" -o /usr/local/sbin/update-ngxblocker \
    && curl -L "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/setup-ngxblocker" -o /usr/local/sbin/setup-ngxblocker \
    && chmod 755 /usr/local/sbin/install-ngxblocker \
    /usr/local/sbin/update-ngxblocker \
    /usr/local/sbin/setup-ngxblocker \
    && sed -i 's/"nginx-debug"/"nginx-debug" -o "$1" = "supervisord"/g' /docker-entrypoint.sh \
    && mkdir /nginx \
    /nginx/dynamic.d \
    /nginx/bots.d \
    /var/log/supervisord \
    /var/log/cron \
    /etc/nginx/stream.conf.d \
    /etc/nginx/mail.conf.d \
    && ln -s /nginx/bots.d /etc/nginx/bots.d \
    && touch /nginx/logrotate.status \
    && ln -s /nginx/logrotate.status /var/lib/logrotate.status

COPY --chown=root:root src /

RUN chmod 755 /docker-entrypoint.d/80-init.sh \
    /usr/local/bin/nginx_real_ip_cdn.sh \
    /usr/local/bin/nginx_resolver.sh \
    /etc/periodic/daily/nginx

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
