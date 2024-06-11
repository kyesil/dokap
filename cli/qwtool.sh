#!/bin/bash
APPS_PATH="/app"

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
        echo -e "\n Userpass : $app : $rpassw \n"
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

resetpass(){
    checkroot
    confirm "reset user pass $app"
    if id "$app" >/dev/null 2>&1; then
        rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        skill -KILL -u $app
        usermod -p $(openssl passwd -1 $rpassw) $app
        echo -e "\n Userpass : $app : $rpassw \n"
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
        echo "removed gitpath: $gitpath"
    fi
    if id "$app" >/dev/null 2>&1; then
        skill -KILL -u $app
        userdel -f $app
        echo "user exist removed : $app"
    fi
	
	if [ -d "$apath" ]; then
		confirm "remove app folder $apath"
        cd  "$APPS_PATH"
        rm -rf "$apath"
        echo "removed apath: $apath"
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
        git pull
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
    (app) create [sitename proxyport] #only with sudo
    (app) clone  (giturl)
    (app) remove #only with sudo
    (app) update  #down pull up
    (app) keyrgen  #regenrate sshkey
    (app) resetpass  #regenrate userpass
    (app) logs [type] #docker compose log -f
    (app) start  #docker compose up
    (app) stop #docker compose down
    "
}


if [[ -z "$2" || -z "$1" ]]; then
    help
else

    $2
fi
