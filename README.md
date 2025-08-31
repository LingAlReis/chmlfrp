# Chmlfrp
## Directory Hierarchy
```
|—— Dockerbuild.sh
|—— Dockerfile
```

## Docker Compose
```
services:
  # chmlfrpc
  chmlfrpc:
    image: harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
    container_name: chmlfrpc
    hostname: chmlfrpc
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - LANG=en_US.UTF-8
      - FRPC_USER=
      - FRPC_PROXY=
    restart: always

networks:
  local:
    external: true
```
