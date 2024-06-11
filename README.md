# dokkap

## Start

```bash
docker network create traefik_network
docker compose up

## remove all  (data file binded to host)
docker compose down --rmi all --volumes --remove-orphans

```
## create  a project
```bash
./cli/qwtool.sh help

```