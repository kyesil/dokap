#!/bin/bash

help() {
    echo "
Usage $0 --app=appname --domain=example.com --proxyport=9001 --repo=https://github...
    "
}
# new_project.sh --app=aquaguide --domain=*.aqua.guide --git=


while [ "$#" -gt 0 ]; do
    case "$1" in
        --app=*) APP="${1#*=}"; shift 1;;
        --domain=*) DOMAIN="${1#*=}"; shift 1;;
        --proxyport=*) PROXYPORT="${1#*=}"; shift 1;;
        --repo=*) REPO="${1#*=}"; shift 1;;
        
        -*) echo "unknown option: $1" >&2; exit 1;;
        *) echo "main=$1"; shift 1;;
    esac
done

echo "$APP"
echo "$DOMAIN"
echo "$PROXYPORT"
echo "$REPO"

value=""
param="--ssdsds"

if [[ -z "$value" && "${param:0:2}" != "--" ]]; then
    echo " yes"
else
    echo "no"
fi