#!/bin/bash
source $(dirname "$0")/_utils.sh

params_usage="--app=appname" #for parse_params (optional)
params_req="app" #for parse_params (optional)
params_prefix="qw_" #for parse_params (optional)
parse_params "$@" #pass all parameters
echo $qw_app # get exported value

confirm "stop, git update and start $qw_app"

initpaths # $apath $sshpath $gitpath

if [-d "$gitpath"]; then
    cd "$gitpath"
    git config --global --add safe.directory "$gitpath"
    git reset --hard
    git pull
else
    echo "gith path not found : $gitpath"
fi