FROM nginx:stable-alpine

ARG BUILD_DATE
#ARG BUILD_REVISION

LABEL org.opencontainers.image.title="nginx"
#LABEL org.opencontainers.image.description=""
#LABEL org.opencontainers.image.authors=""
LABEL org.opencontainers.image.vendor="Rudi2e"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="0.1.5"
LABEL org.opencontainers.image.source="https://github.com/rudi2e/docker-nginx.git"
#LABEL org.opencontainers.image.revision="$BUILD_REVISION"
LABEL org.opencontainers.image.created="$BUILD_DATE"

RUN if [ "$(uname -m)" = "aarch64" ]; then \
        [ -x "/usr/bin/run-parts" ] || ln -s /bin/run-parts /usr/bin/run-parts; \
    fi \
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
    && sed -i 's/logrotate \/etc\/logrotate.conf/logrotate -s \/nginx\/logrotate.status \/etc\/logrotate.conf/g' /etc/periodic/daily/logrotate \
    && mkdir /nginx \
    /nginx/dynamic.d \
    /nginx/bots.d \
    /var/log/supervisor \
    /var/log/cron \
    /etc/nginx/stream.conf.d \
    /etc/nginx/mail.conf.d \
    && ln -s /nginx/bots.d /etc/nginx/bots.d \
    && mv /etc/periodic/daily/logrotate /etc/periodic/15min/logrotate

COPY --chown=root:root rootfs /

RUN chmod 755 /docker-entrypoint.d/80-init.sh \
    /usr/local/bin/nginx_real_ip_cdn.sh \
    /usr/local/bin/nginx_resolver.sh \
    /etc/periodic/daily/nginx

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
