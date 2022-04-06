# Customized Nginx Docker Image

## Included compartment
- [Official Nginx Docker Image](https://hub.docker.com/_/nginx)
- [Nginx Ultimate Bad Bot & Referrer Blocker](https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker)
- Logrotate
- Cron
- Custom script

## Environment variables

| Name                           | Description |
|--------------------------------|-------------|
| REAL_IP_CDN_PROVIDER           | `all`: 모든 CDN의 IP를 받아옵니다.<br>`[Provider [Provider2] [...]]`: 해당 CDN의 IP를 받아옵니다. |
| NGINX_ULTIMATE_BAD_BOT_BLOCKER | `true`: Nginx Ultimate Bad Bot & Referrer Blocker의 자동 업데이트를 활성화합니다. |
