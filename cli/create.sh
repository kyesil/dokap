#!/bin/bash
source $(dirname "$0")/_utils.sh
echo $(dirname "$0")
params_usage="--app=appname --domain=example.com --proxyport=9001 --repourl=\"https://github...\"" #for parse_params (optional)
params_req="app domain proxyport repourl" #for parse_params (optional)
params_prefix="qw_" #for parse_params (optional)
parse_params "$@" #pass all parameters
echo $qw_app # get exported value
checkroot

confirm "create user/ git clone  for  $qw_app"

initpaths # $apath $sshpath $gitpath

mkdir -p $sshpath
if id "$qw_app" >/dev/null 2>&1; then
    echo "User exist only fixing project"
else
    rpassw=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    useradd -p $(openssl passwd -1 $rpassw) -G docker -s /bin/bash  -d $apath $qw_app
    echo -e "\n Userpass : $qw_app : $rpassw \n"
fi
chown -R $qw_app $apath
chmod 750 -R $apath
echo "User added  $? "

if [-d "$gitpath"]; then
    echo "clone folder exist skip clone"
else
    git clone --depth 1 $qw_repourl $gitpath
    #ssh-agent bash -c "ssh-add $sshpath/id_rsa; git clone --depth 1 $2 $gitpath"
    chown -R $qw_app $gitpath
    chmod 750 -R $gitpath
    git config --global --add safe.directory $gitpath
fi