# 拉去基础镜像
FROM alpine:latest

# 创建工作空间
WORKDIR /app

# 安装基础命令
RUN apk add --no-cache wget

# 下载基础包
RUN wget https://minio.5210125.xyz:12443/public/software/chmlfrp/0.51.2/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz && \
    tar -zxf ChmlFrp-0.51.2_240715_linux_amd64.tar.gz && \
    cd ChmlFrp-0.51.2_240715_linux_amd64 && \
    chmod +x frpc && \
    mv frpc /app/ && \
    cd /app && \
    rm -rf ChmlFrp-0.51.2_240715_linux_amd64 ChmlFrp-0.51.2_240715_linux_amd64.tar.gz

# 添加启动脚本
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo '/app/frpc -u "${FRPC_USER}" -p "${FRPC_PROXY}"' >> /app/start.sh && \
    chmod +x /app/start.sh

# 执行启动脚本
ENTRYPOINT ["/app/start.sh"]
