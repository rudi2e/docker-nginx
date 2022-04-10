#!/usr/bin/env sh
### Copyright (c) Rudi2e

dynamic_d_directory="/nginx/dynamic.d"

[ -d "$dynamic_d_directory" ] || mkdir "$dynamic_d_directory"
[ -d "/nginx/bots.d" ] || mkdir /nginx/bots.d
[ -e "/nginx/logrotate.status" ] || touch /nginx/logrotate.status

[ -d "/var/log/nginx" ] || mkdir /var/log/nginx
[ -d "/var/log/supervisord" ] || mkdir /var/log/supervisord

if [ -x "$(command -v nginx_real_ip_cdn.sh)" ]; then
    if [ "$REAL_IP_CDN_PROVIDER" = "all" ]; then
        nginx_real_ip_cdn.sh -a -o "${dynamic_d_directory}"
    elif [ -n "$REAL_IP_CDN_PROVIDER" ]; then
        nginx_real_ip_cdn.sh -p "$REAL_IP_CDN_PROVIDER" -o "${dynamic_d_directory}"
    fi
fi

if [ -x "$(command -v nginx_resolver.sh)" ]; then
    nginx_resolver.sh -o "${dynamic_d_directory}/resolver.conf"
fi

if [ "$NGINX_ULTIMATE_BAD_BOT_BLOCKER" = "true" ] && [ -x "$(command -v install-ngxblocker)" ] && [ -x "$(command -v update-ngxblocker)" ]; then
    update-ngxblocker -c "$dynamic_d_directory" -b /nginx/bots.d -i "$(command -v install-ngxblocker)"
fi
