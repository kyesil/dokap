# dokkap

## Remove All Docker Containers, Images and Volumes

```bash
docker network create traefik_network
docker compose up

## remove all  (data file binded to host)
docker compose down --rmi all --volumes --remove-orphans
```