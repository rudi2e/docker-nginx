#!/usr/bin/env sh
### Copyright (c) Rudi2e

DIRNAME=$(dirname "$0")
BASENAME=$(basename "$0")

input_file="/etc/resolv.conf"
output_file="resolver.conf"

if ! [ -x "$(command -v md5sum)" ] || ! [ -x "$(command -v awk)" ]; then
    echo $BASENAME: one or more binaries not found
    exit 1
fi

Usage() {
    cat <<EOF
Nginx_Resolver.sh: Nginx resolver config maker
Copyright (c) Rudi2e

$BASENAME [-i input_file] [-o output_file]
EOF
}

while getopts ":i:o:" opt; do
    case $opt in
        i)
            input_file="$OPTARG"
            ;;
        o)
            if [ -d "$OPTARG" ]; then
                echo $BASENAME: $OPTARG is directory
                exit 1
            else
                output_file="$OPTARG"
            fi
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

if [ -e "$input_file" ] && [ -n "$(cat $input_file)" ]; then
    resolver_address=$(awk '$1 == "nameserver" { print ($2 ~ ":") ? "["$2"]" : $2 } BEGIN { ORS=" " }' "$input_file")
else
    echo $BASENAME: $input_file file not found or zero length
    exit 1
fi

new_config="resolver $resolver_address;"

if [ -e "$output_file" ]; then
    old_config_hash=$(cat "$output_file" | md5sum)
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
    if >> "$output_file"; then
        echo "$new_config" > "$output_file"
    else
        echo $BASENAME: $new_config write permission denied
        exit 1
    fi
fi
