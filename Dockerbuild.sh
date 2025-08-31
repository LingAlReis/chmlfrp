#!/bin/sh

# 构建
docker rmi harbor.5210125.xyz:12443/library/chmlfrp/frpc:0.51.2
docker build -t harbor.5210125.xyz:12443/library/chmlfrp/frpc:0.51.2 .

# 标签
docker rmi harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
docker tag harbor.5210125.xyz:12443/library/chmlfrp/frpc:0.51.2 harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest

# 推送
docker login harbor.5210125.xyz:12443
docker push harbor.5210125.xyz:12443/library/chmlfrp/frpc:0.51.2
docker push harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
