#!/bin/bash

#  ln -s /app/qw.sh /usr/bin/qw

help() {
    echo "
Usage ./qw (action) [param1....]\n
   Commands:
    remove #only with sudo
    update  #git pull 
	upgrade  #stop gitpull start
    createkey  #regenrate sshkey
    showkey  #regenrate sshkey
    resetpass  #regenrate userpass
    logs [-f] #docker compose log -f
    status  (app) start  #docker compose up
    start  #docker compose up
    stop #docker compose down
    "
}


if [[ -z "$1" ]]; then
    help
else
    if [[ "$1" == "_ps" ]]; then
        qwtool ps
        exit 0
    fi
    qwtool $USER "$@"
fi
