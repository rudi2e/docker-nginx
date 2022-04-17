#!/usr/bin/env sh
### Copyright (c) Rudi2e

DIRNAME=$(dirname "$0")
BASENAME=$(basename "$0")

output_directory="."

if ! [ -x "$(command -v md5sum)" ] || ! [ -x "$(command -v curl)" ] || ! [ -x "$(command -v jq)" ]; then
    echo $BASENAME: one or more binaries not found
    exit 1
fi

Usage() {
    cat <<EOF
Nginx_Real_IP_CDN.sh: Renew CDNs IP
Copyright (c) Rudi2e

$BASENAME [-o output_directory] [-p provider | -a]
EOF
}

Download() {
    if [ -n "$1" ]; then
        {
            downloaded=$(curl -s "$1")
        } || {
            echo $BASENAME: Failed download $1
            return 1
        }

        if [ -z "$downloaded" ]; then
            echo $BASENAME: downloaded file is zero length
            return 1
        fi
    fi
}

WriteRealIP() {
    for write_real_ip_i in ${*}; do
        set_real_ip_new_config="${set_real_ip_new_config}
set_real_ip_from ${write_real_ip_i};"
        geo_real_ip_new_config="${geo_real_ip_new_config}
    ${write_real_ip_i}    1;"
    done
}

RealIPProvider() {
    case "$1" in
        cloudflare)
            {
                Download "https://www.cloudflare.com/ips-v4"
            } || {
                return 1
            }
            set_real_ip_new_config="#################### Cloudflare - IPv4 ####################"
            geo_real_ip_new_config='geo $realip_remote_addr $__http_cloudflare_ip {
    default 0;'
            WriteRealIP "${downloaded}"

            {
                Download "https://www.cloudflare.com/ips-v6"
            } || {
                return 1
            }
            set_real_ip_new_config="${set_real_ip_new_config}

#################### Cloudflare - IPv6 ####################"
            WriteRealIP "${downloaded}"
            geo_real_ip_new_config="${geo_real_ip_new_config}
}"
            ;;
        cloudfront)
            {
                Download "https://ip-ranges.amazonaws.com/ip-ranges.json"
            } || {
                return 1
            }
            set_real_ip_new_config="#################### CloudFront - IPv4 ####################"
            geo_real_ip_new_config='geo $realip_remote_addr $__http_cloudfront_ip {
    default 0;'
            WriteRealIP $(echo ${downloaded} | jq '.prefixes[] | select(.service == "CLOUDFRONT") | .ip_prefix')

            set_real_ip_new_config="${set_real_ip_new_config}

#################### Cloudfront - IPv6 ####################"
            WriteRealIP $(echo ${downloaded} | jq '.ipv6_prefixes[] | select(.service == "CLOUDFRONT") | .ipv6_prefix')
            geo_real_ip_new_config="${geo_real_ip_new_config}
}"
            ;;
        fastly)
            {
                Download "https://api.fastly.com/public-ip-list"
            } || {
                return 1
            }
            set_real_ip_new_config="#################### Fastly - IPv4 ####################"
            geo_real_ip_new_config='geo $realip_remote_addr $__http_fastly_ip {
    default 0;'
            WriteRealIP $(echo ${downloaded} | jq '.addresses[]')

            set_real_ip_new_config="${set_real_ip_new_config}

#################### Fastly - IPv6 ####################"
            WriteRealIP $(echo ${downloaded} | jq '.ipv6_addresses[]')
            geo_real_ip_new_config="${geo_real_ip_new_config}
}"
            ;;
        *)
            echo $BASENAME: Invalid provider $1
            return 1
            ;;
    esac
}

while getopts ":o:p:a" opt; do
    case $opt in
        o)
            output_directory="$OPTARG"
            ;;
        p)
            provider="$OPTARG"
            ;;
        a)
            provider="cloudflare cloudfront fastly"
            ;;
        :)
            echo $BASENAME: -$OPTARG is required argument
            exit 1
            ;;
        ?)
            echo $BASENAME: -$OPTARG is invalid option
            Usage
            exit 1
            ;;
        *)
            Usage
            ;;
    esac
done

if ! [ -d "$output_directory" ]; then
    echo $BASENAME: $output_directory is not directory
    exit 1
fi

for i in $provider; do
    {
        RealIPProvider "$i"
    } || {
        echo $BASENAME: $i error occurred. Skip renew
        continue
    }

    for j in set geo; do
        real_ip_filename="${output_directory}/${j}_real_ip_${i}.conf"

        if [ "$j" = "set" ]; then
            new_config="$set_real_ip_new_config"
        elif [ "$j" = "geo" ]; then
            new_config="$geo_real_ip_new_config"
        fi

        if [ -e "$real_ip_filename" ]; then
            old_config_hash=$(cat "$real_ip_filename" | md5sum)
            new_config_hash=$(echo "$new_config" | md5sum)

            if [ "$old_config_hash" = "$new_config_hash" ]; then
                compare_result="true"
            else
                compare_result="false"
            fi
        else
            compare_result="false"
        fi

        if [ "$compare_result" = "false" ]; then
            if >> "$real_ip_filename"; then
                echo "$new_config" > "$real_ip_filename"
            else
                echo $BASENAME: $real_ip_filename write permission denied
                exit 1
            fi
        fi
    done
done
