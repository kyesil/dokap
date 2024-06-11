#!/bin/bash

APPS_PATH="/app"

help() {
    echo "
Usage $0 $params_usage
    "
}

parse_params() {
    params_req=($params_req)
    for param in "$@"; do
        IFS='=' # spit =
        local array=($param)
        unset IFS;
        local key=${array[0]//'-'/''} # replace -
        local value=${array[1]}
        if [[ -z "$value" && "${param:0:2}" != "--" ]]; then
            eval "${params_prefix}pmain += $key"
        fi
        eval "$params_prefix$key=$value"
    done
    
    for rp in "${params_req[@]}"; do
        eval "local v=\$$params_prefix$rp"
        echo "$rp => $v"
        if [[ -z "$v" ]]; then
            echo "Error: required param --$rp"
            help
            exit 1
            break
        fi
    done
}

initpaths(){
    apath="$APP_PATH/$qw_app"
    sshpath="$apath/.ssh"
    gitpath="$apath/${qw_app}git"
}

confirm() {
    local text="Do you want to proceed? (Y/N)"
    if [[ -n "$1" ]]; then
        text="$1? (Y/N)"
    fi
    while true; do
        read -p "Do you want to proceed? (Y/N) " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            [Cc]*) exit ;;
            *) echo "Please answer Y, N, or C." ;;
        esac
    done
}

checkroot() {
    if [ "$EUID" -ne 0 ]; then
        print "please run root"
        exit
    fi
}