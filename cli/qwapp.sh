#!/bin/bash

confirm() {
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

init() {
    checkroot
    confirm
    apath="/app/$1"
    sshpath="$apath/.ssh"
    mkdir -p $sshpath
    
    chmod 777 -R $apath
    if id "$1" >/dev/null 2>&1; then
        echo "User exist skip"
    else
        rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        useradd -p $(openssl passwd -1 $rpassw) -G docker -s /bin/bash  -d $apath $1
        echo -e "\n Userpass : $1 : $rpassw \n"
    fi
    echo "Useradd  $?"
	
    # if [-f "$sshpath/id_rsa.pub"]; then
    #   echo -e "ssh key exist"
    #    cat $sshpath/id_rsa.pub
	#	echo -e "\n------------rsa_pub----------\n"
    # else
    #   keyrgen $1
    #fi
    if [ -z "$2" ]; then # $2=sitedomain
        echo "skip nginx certbot"
    else
        initweb $1 $2 $3
    fi
	
    
}

resetpass(){
    rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    skill -KILL -u $1
    usermod -p $(openssl passwd -1 $rpassw) $1
}

keyrgen(){
    apath="/app/$1"
    sshpath="$apath/.ssh"
    cd $sshpath
    rm ./*
    ssh-keygen -q -t rsa -b 2048 -C $1 -N '' -f ./id_rsa <<<y >/dev/null 2>&1
    cat ./id_rsa.pub >>./authorized_keys
    
    chmod 700 ./
    chmod 600 ./authorized_keys
    chown -R $1 $apath
    echo -e "\n------------rsa_pub----------\n"
    cat ./id_rsa.pub
	echo -e "\n------------rsa_pub----------\n"
}

remove() {
    checkroot
    confirm
    skill -KILL -u $1
    userdel -f $1
    rm -rf /app/$1
    rm /etc/systemd/system/docker-$1.service
    if [ -z "$2" ]; then
        echo "skip nginx certbot remove"
    else
        rm /etc/nginx/sites-enabled/$2
        certbot delete --cert-name $2
    fi
	
    
}

clone() {
    apath="/app/$1"
    sshpath="$apath/.ssh"
	gitpath="$apath/${1}git"
	if [-d "$gitpath"]; then
	   echo "clone folder exist skip" 
    else
	  git clone --depth 1 $2 $gitpath
      #ssh-agent bash -c "ssh-add $sshpath/id_rsa; git clone --depth 1 $2 $gitpath"
	  chown -R $1 $gitpath 
	  git config --global --add safe.directory $gitpath
    fi

}

update() {
    apath="/app/$1"
    sshpath="$apath/.ssh"

    cd "$apath/${1}git"
	git config --global --add safe.directory "$apath/${1}git"
    git reset --hard
	git pull
	# ssh-agent bash -c "ssh-add $sshpath/id_rsa; git pull"
}

start(){
 cd "/app/$1/${1}git"
 docker compose up -d
 docker update --restart always $(docker compose ps -q)
 docker compose ps --all
}
stop(){
 cd "/app/$1/${1}git"
 docker compose down --rmi all --volumes --remove-orphans
 docker compose ps --all
}

logs(){
 cd "/app/$1/${1}git"
 docker compose ps --all
 docker compose logs $2
}

initweb() {

	if [ -z "$3" ]; then #$3 port
        echo "site must have proxy port"
		exit
    fi
    certbot certonly --dns-cloudflare -d $2 -d *.$2 --agree-tos --preferred-challenges dns-01 --register-unsafely-without-email --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare-propagation-seconds 42
    
    echo "

server {
    listen 80;
    server_name $2;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $2;

  location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_pass http://127.0.0.1:${3};
    }



 # SSL
  ssl_certificate /etc/letsencrypt/live/$2/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$2/privkey.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/$2/chain.pem;

# protocols
ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3; ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
# HSTS, remove # from the line below to enable HSTS
add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;
# OCSP Stapling
ssl_stapling on; ssl_stapling_verify on;
}
    " >/etc/nginx/sites-enabled/$2
    service nginx reload
}

help() {
    echo "
Usage ./qwapp.sh (command) [param1....]\n
   Commands:
    init (name) [sitename proxyport] #only with sudo
    clone (name) (giturl)
    remove (name) #only with sudo
    update (name)  #down pull up
    keyrgen (name)  #regenrate sshkey
    resetpass (name)  #regenrate userpass
	dlogs (name)  #docker compose log
	start (name)  #docker compose up
	stop (name)  #docker compose down
    "
}
if [ -z "$1" ]; then
    help
else
    $1 "$2" "$3" "$4" "$5"
fi
