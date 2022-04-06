FROM nginx:stable-alpine

LABEL maintainer="rudi2e"
LABEL title="nginx"
LABEL version="0.1.1"
LABEL description=""

RUN apk add --no-cache supervisor logrotate jq curl ca-certificates \
 && rm -rf /var/cache/apk/* \
 && update-ca-certificates \
 && curl -L "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker" -o /usr/local/bin/install-ngxblocker \
 && curl -L "https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/update-ngxblocker" -o /usr/local/bin/update-ngxblocker \
 && chmod 755 /usr/local/bin/install-ngxblocker \
              /usr/local/bin/update-ngxblocker \
 && sed -i 's/"nginx-debug"/"nginx-debug" -o "$1" = "supervisord"/g' /docker-entrypoint.sh \
 && mkdir /nginx \
          /nginx/dynamic.d \
          /nginx/bots.d \
          /var/log/supervisord \
          /etc/nginx/stream.conf.d \
          /etc/nginx/mail.conf.d \
 && ln -s /nginx/bots.d /etc/nginx/bots.d

COPY --chown=root:root etc /
COPY --chown=root:root docker-entrypoint.d /
COPY --chown=root:root bin /usr/local

RUN chmod 755 /docker-entrypoint.d/80-init.sh \
              /usr/local/bin/nginx_real_ip_cdn.sh \
              /usr/local/bin/nginx_resolver.sh \
              /etc/periodic/daily/nginx

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
