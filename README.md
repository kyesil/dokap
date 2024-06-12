# dokkap

## Start with traefik (not complete now run caddy server)

```bash
docker network create traefik_network
docker compose up

## remove all  (data file binded to host)
docker compose down --rmi all --volumes --remove-orphans

```

## usage cli

```bash
sudo ln -s /app/dokap/dokapgit/cli/qwtool.sh /usr/bin/qwtool
sudo chmod 755 /usr/bin/qwtool
qwtool help

```

## caddy server install 
```bash
### caddy install 
## https://caddyserver.com/docs/install#debian-ubuntu-raspbian 

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

### watch mode config

/lib/systemd/system/caddy.service
//add --watch
/usr/bin/caddy run --environ --watch --config /etc/caddy/Caddyfile

systemctl reenable caddy
journalctl -f -u caddy


## config structure
 nano /etc/caddy/Caddyfile
below :
	import sites/*
mkdir  /etc/caddy/sites/

nano /etc/caddy/sites/_globals

{
  email admin@solideleectron.com
}

## global vars
(_globals) {
  header {
	Strict-Transport-Security "max-age=31536000; includeSubdomains"
  }

  handle /health {
   respond "okkk"
 }
 
 log {
  level INFO
  output stdout
 }

}

(_wildcard) {
 tls {
	dns cloudflare myapikey
 }
}
## usage  sites/lan.predixi.com
lan.predixi.com {
 import _globals
 reverse_proxy  192.168.0.20:80
}



## xcaddy instyall
 // go install 
wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz 
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
nano $HOME/.profile
     export PATH=$PATH:/usr/local/go/bin

export PATH=$PATH:/usr/local/go/bin

// https://github.com/caddyserver/xcaddy#install

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-xcaddy.list
sudo apt update
sudo apt install xcaddy

## caddy-exec
 // go install sudo 
wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz 
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz

xcaddy build --with github.com/abiosoft/caddy-exec

remove all logs 

rm -rf /var/log/*.gz && rm -rf /var/log/*.1 && rm -rf /var/log/*.log.*

```
