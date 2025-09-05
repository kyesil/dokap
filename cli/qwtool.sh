#!/bin/bash
#  ln -s /app/qwtool.sh /usr/bin/qwtool

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
    
    if id "$app" >/dev/null 2>&1; then
        echo "User exist only fixing project"
		showkey
    else
        rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        useradd -p $(openssl passwd -1 $rpassw) -G docker -s /bin/bash  -d $apath $app
        echo -e "\n $? Userpass : $app : $rpassw \n"
		mkdir -p $apath
		chown $app:$app -R $apath/
		su - "$app" -c "mkdir -p $sshpath"
		createkey
		echo "Devam etmek için 'q' tuşuna bas..."
		while true; do	
			read -n1 -s key   
			if [[ $key == "q" ]]; then
				break
			fi
		done
    fi
    echo "User added  $? "
    if [ -d "$gitpath" ]; then
        echo "clone folder exist. skip clone: $gitpath"
    else
		su - "$app" -c "mkdir -p $gitpath"
		git config --global --add safe.directory $gitpath
        git config --global core.autocrlf false
		su - "$app" -c "git clone --depth 1 '$xparam' '$gitpath'"
		chown $app:$app -R $gitpath/
        #ssh-agent bash -c "ssh-add $sshpath/id_rsa; git clone --depth 1 $2 $gitpath"
    fi
    
}

addsite(){
    local proxyport=$xparam
    local domain=$yparam
    if [[ -z "$proxyport" || -z "$domain"  ]]; then
        echo "please provide proxport and domain ";
        exit 1
    fi
    # local domainfn="${domain//'*'/'+'}" #filename * replace +
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

createkey(){
    confirm "remove all and regenerate sshkey $app"
    cd $sshpath
    rm -rf $sshpath/*
	
	su - $app -c "ssh-keygen -t ed25519 -C \"$app@dokap\" -f ~/.ssh/id_ed25519 -N '' >/dev/null 2>&1 "
	#su - "$app" -c "ssh-add $sshpath/id_ed25519"
    #ssh-keygen -q -t ed25519 -C $app -f ./id_ed25519 <<<y >/dev/null 2>&1
    #cat ./id_ed25519.pub >>./authorized_keys
	chmod 700 $sshpath
	chown $app:$app -R $sshpath/
    chmod 600 "$sshpath/id_ed25519"
	chmod 644 "$sshpath/id_ed25519.pub"
	ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> $sshpath/known_hosts
	chmod 644 $sshpath/known_hosts

    echo -e "\n------------rsa_ed25519----------\n"
    cat ./id_ed25519.pub
    echo -e "\n------------rsa_ed25519----------\n"
}
showkey(){
    cd $sshpath
    echo -e "\n------------rsa_ed25519----------\n"
    cat ./id_ed25519.pub
    echo -e "\n------------rsa_ed25519----------\n"
}

fixperm(){
	checkroot
	confirm " yapılsın mı ? 
	chown $app:$app -R $sshpath/
	chown $app:$app -R $gitpath/
	chmod 777 -R $apath/_*
	chmod 777 -R $gitpath/
	chmod 700 $sshpath
    chmod 600 $sshpath/id_ed25519
	chmod 644 $sshpath/id_ed25519.pub
	chmod 644 $sshpath/known_hosts
	"

	chown $app:$app -R $sshpath/
	chown $app:$app -R $gitpath/
	chmod 777 -R $apath/_*
	chmod 777 -R $gitpath/
	chmod 700 $sshpath
    chmod 600 $sshpath/id_ed25519
	chmod 644 $sshpath/id_ed25519.pub
	chmod 644 $sshpath/known_hosts
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
    
    if ls ${CADDY_PREFIX}${app} 1> /dev/null 2>&1; then
        rm -rf ${CADDY_PREFIX}${app}
        echo "removed caddyfile $?"
        service caddy reload
    fi
}


update() {
    confirm "git reset & pull $app"
    checkpath $gitpath
	cd "$gitpath"
	git config --global --add safe.directory "$gitpath"
	git reset --hard
	git clean -d -f .
	git pull --force
	chown $app:$app -R $gitpath/   
}
upgrade() {
	update
	stop
	start
}

DC() {
	checkpath $gitpath
	cd "$gitpath"
	local cf
	local compose_f
	for cf in  "docker-compose.yml" "compose.yml" "compose-prod.yml"; do
		if [ -f "$cf" ]; then
			if [ "$1" = "up" ]; then
				yq -i 'del(.services[].image)' "$cf"
			fi
			compose_f=$cf
		fi
	done
	echo "compose file = $compose_f"
	docker compose -f "$compose_f" -p "$app" "$@"
}

start(){
    checkpath $gitpath
	cd "$gitpath"
	#yq -i '.services |= with_entries(.value.user = "1000:1000")' compose*.yml
	
	DC up -d
	#docker update --restart unless-stopped $(docker compose ps -q)
	DC ps --all
    
}
stop(){
    checkpath $gitpath
	cd "$gitpath"
	DC ps --all
	DC down --rmi all --volumes --remove-orphans
	DC ps --all
}

log(){
    checkpath $gitpath
	cd "$gitpath"
	DC ps --all
	DC logs $xparam
}

status(){
	checkpath $gitpath
	cd "$gitpath"
	DC ps --all
	DC stats --no-stream --all
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

checkpath() {
    local path="$1"
    if [ ! -e "$path" ]; then
        echo "❌ Hata: '$path' bulunamadı."
        exit 1
    fi
}

checkroot() {
    if [ "$EUID" -ne 0 ]; then
        print "please run root"
        exit
    fi
}


help() {
    echo "
Usage ./qwtool (app) (action) [param1....]\n
   Commands:
    (app) create (giturl)#only with sudo
    (app) addsite (proxpass) (domain)
    (app) remove #only with sudo
    (app) update  #git pull 
	(app) upgrade  #stop gitpull start
	(app) fixperm #only with sudo
    (app) createkey  #regenrate sshkey
    (app) showkey  #regenrate sshkey
    (app) resetpass  #regenrate userpass
    (app) logs [-f] #docker compose log -f
    (app) status  (app) start  #docker compose up
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
