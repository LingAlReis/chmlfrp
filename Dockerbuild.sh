#!/bin/sh

# 进入工作空间
cd /mnt/pve/local-data/workspace/code/chmlfrp

# 构建镜像
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 \
-t harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest \
--no-cache --progress=plain -f ./Dockerfile --push .
