#!/bin/bash
APPS_PATH="/app"
CADDY_PREFIX="/etc/caddy/sites/w_"

app="$1"
action="$2"
xparam="$3"
yparam="$4"
apath="$APPS_PATH/$app"
sshpath="$apath/.ssh"
gitpath="$apath/${app}git"

create() {
    checkroot
    confirm "create user/ git clone  for $app"
    mkdir -p $sshpath
    if id "$app" >/dev/null 2>&1; then
        echo "User exist only fixing project"
    else
        rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        useradd -p $(openssl passwd -1 $rpassw) -G docker -s /bin/bash  -d $apath $app
        echo -e "\n $? Userpass : $app : $rpassw \n"
    fi
    chown -R $app $apath
    chmod 750 -R $apath
    echo "User added  $? "
    
    if [ -d "$gitpath" ]; then
        echo "clone folder exist. skip clone: $gitpath"
    else
        git clone --depth 1 $xparam $gitpath
        #ssh-agent bash -c "ssh-add $sshpath/id_rsa; git clone --depth 1 $2 $gitpath"
        chown -R $app $gitpath
        chmod 750 -R $gitpath
        git config --global --add safe.directory $gitpath
    fi
    
}

addsite(){
    local proxyport=$xparam
    local domain=$yparam
    if [[ -z "$proxyport" || -z "$domain"  ]]; then
        echo "please provide proxport and domain ";
        exit 1
    fi
    local wildcard=""
    if [[ $domain == "*"* ]]; then # starts with star
        echo "wildcard found $domain"
        wildcard="import _wildcard"
        domain="$domain, ${domain:2}"
    fi
    
    local conffile="${CADDY_PREFIX}${app}"
    
    if [ -f "$conffile" ]; then
        echo "file exist skip replacing";
    fi
    
    echo "
$domain {
 import _globals
 reverse_proxy  127.0.0.1:$proxyport
 $wildcard
}
    " >$conffile
    
    service caddy reload
    caddy validate --config /etc/caddy/Caddyfile
    sleep 3
    service caddy status
}

resetpass(){
    checkroot
    confirm "reset user pass $app"
    if id "$app" >/dev/null 2>&1; then
        rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        skill -KILL -u $app
        usermod -p $(openssl passwd -1 $rpassw) $app
        echo -e "\n $? Userpass : $app : $rpassw \n"
    else
        echo "user not exist : $app"
    fi
    
}

sshkeygen(){
    confirm "remove all and regenerate sshkey $app"
    cd $sshpath
    rm ./*
        ssh-keygen -q -t rsa -b 2048 -C $app -N '' -f ./id_rsa <<<y >/dev/null 2>&1
        cat ./id_rsa.pub >>./authorized_keys
    
    chmod 700 ./
    chmod 600 ./authorized_keys
    chown -R $app $apath
    echo -e "\n------------rsa_pub----------\n"
    cat ./id_rsa.pub
    echo -e "\n------------rsa_pub----------\n"
}

remove() {
    checkroot
    confirm "stop, remove user and delete git folder $app"
    
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        stop
        cd  "$APPS_PATH"
        rm -rf $gitpath
        echo "removed gitpath $?: $gitpath"
    fi
    if id "$app" >/dev/null 2>&1; then
        skill -KILL -u $app
        userdel -f $app
        echo "user exist removed $? : $app"
    fi
    
    if ls ${CADDY_PREFIX}${app}_* 1> /dev/null 2>&1; then
        rm -rf ${CADDY_PREFIX}${app}
        echo "remove caddyfile $?"
        service caddy reload
    fi
}

clone() {
    if [ -d "$gitpath" ]; then
        echo "clone folder exist skip: "$gitpath""
    else
        git clone --depth 1 $xparam $gitpath
        chown -R $app $gitpath
        git config --global --add safe.directory "$gitpath"
    fi
}

update() {
    confirm "git reset & pull $app"
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        git config --global --add safe.directory "$gitpath"
        git reset --hard
        git clean -d -f .
        git pull --force
    else
        echo "git path not found : $gitpath"
    fi
}

start(){
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        docker compose up -d
        docker update --restart unless-stopped $(docker compose ps -q)
        docker compose ps --all
    else
        echo "git path not found : $gitpath"
    fi
}
stop(){
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        docker compose ps --all
        docker compose down --rmi all --volumes --remove-orphans
        docker compose ps --all
    else
        echo "gith path not found : $gitpath"
    fi
}

log(){
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        docker compose ps --all
        docker compose logs $xparam
    else
        echo "gith pat not found : $gitpath"
    fi
}

status(){
    if [ -d "$gitpath" ]; then
        cd "$gitpath"
        docker compose ps --all
        docker compose stats --no-stream --all
    else
        echo "gith pat not found : $gitpath"
    fi
}

parse_params() {
    params_req=($1)
    for param in "$@"; do
        if [[ "${param:0:2}" == "--" ]]; then
            IFS='=' # spit =
            local array=($param)
            unset IFS;
            local key=${array[0]//'-'/''} # replace -
            local value=${array[1]}
            eval "qw_$key=$value"
        fi
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

confirm() {
    local text="Do you want to proceed?"
    if [[ -n "$1" ]]; then
        text="$1?"
    fi
    while true; do
        read -p "$text (Y/N) " yn
        case $yn in
            [Yy]*) return 0 ;;
            # [Nn]*) return 1 ;;
            [Nn]*) echo "CANCELED" & exit 1 ;;
            [Cc]*) echo "CANCELED" & exit ;;
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


help() {
    echo "
Usage ./qwtool.sh (app) (action) [param1....]\n
   Commands:
    (app) create (giturl)
    (app) addsite (proxpass) (domain)
    (app) remove #only with sudo
    (app) update  #down pull up
    (app) keyrgen  #regenrate sshkey
    (app) resetpass  #regenrate userpass
    (app) logs [-f] #docker compose log -f
    (app) status
    (app) start  #docker compose up
    (app) stop #docker compose down
    "
}


if [[ -z "$2" || -z "$1" ]]; then
    help
else
    if [[ "${1}" == "ps" ]]; then
        docker ps
        caddy validate --config /etc/caddy/Caddyfile
        service caddy status
    fi
    $2
fi
