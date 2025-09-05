#!/bin/bash
source $(dirname "$0")/_utils.sh

params_usage="--app=appname" #for parse_params (optional)
params_req="app" #for parse_params (optional)
params_prefix="qw_" #for parse_params (optional)
parse_params "$@" #pass all parameters
echo $qw_app # get exported value

confirm "stop $qw_app"

initpaths # $apath $sshpath $gitpath

if [-d "$gitpath"]; then
    cd "$gitpath"
    docker compose ps --all
    docker compose down --rmi all --volumes --remove-orphans
    docker compose ps --all
else
    echo "gith pat not found : $gitpath"
fi