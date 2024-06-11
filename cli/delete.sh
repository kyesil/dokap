#!/bin/bash
source $(dirname "$0")/_utils.sh
echo $(dirname "$0")
params_usage="--app=appname" #for parse_params (optional)
params_req="app" #for parse_params (optional)
params_prefix="qw_" #for parse_params (optional)
parse_params "$@" #pass all parameters
echo $qw_app # get exported value
checkroot

confirm "delete git folder $qw_app"

initpaths # $apath $sshpath $gitpath

if [-d "$gitpath"]; then
    echo "stop, remove containers and remove gitpath: $gitpath"
    cd "$gitpath"
    docker compose ps --all
    docker compose down --rmi all --volumes --remove-orphans
    docker compose ps --all
    
    cd  "$APP_PATH"
    rm -rf $gitpath
fi

if id "$qw_app" >/dev/null 2>&1; then
    echo "user exist removing : $qw_app"
    skill -KILL -u $qw_app
    userdel -f $qw_app
fi

