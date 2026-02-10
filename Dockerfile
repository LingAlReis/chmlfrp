#
# ChmlFrp Dockerfile with multi-arch support
#

# Set version and build date
ARG BASE_URL="https://minio.5210125.xyz:12443/public/software/chmlfrp/latest"
ARG FRP_VERSION="0.51.2"
ARG BUILD_DATE="251023"

# Set alpine image version
ARG ALPINE_VERSION="3.21"

# Set base images for different architectures
FROM alpine:${ALPINE_VERSION} AS alpine-amd64
ARG FRP_VERSION
ARG BUILD_DATE
ARG BASE_URL
ENV TARGET_ARCH="amd64"
ENV PACKAGE_SUFFIX="amd64"
ENV FRP_PACKAGE="ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_amd64.tar.gz"
ENV FRP_URL="${BASE_URL}/ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_amd64.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-arm64
ARG FRP_VERSION
ARG BUILD_DATE
ARG BASE_URL
ENV TARGET_ARCH="arm64"
ENV PACKAGE_SUFFIX="arm64"
ENV FRP_PACKAGE="ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_arm64.tar.gz"
ENV FRP_URL="${BASE_URL}/ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_arm64.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-armv7
ARG FRP_VERSION
ARG BUILD_DATE
ARG BASE_URL
ENV TARGET_ARCH="armv7"
ENV PACKAGE_SUFFIX="arm"
ENV FRP_PACKAGE="ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_arm.tar.gz"
ENV FRP_URL="${BASE_URL}/ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_arm.tar.gz"

# Build ChmlFrp container
FROM alpine-${TARGETARCH:-amd64}${TARGETVARIANT}

# Transfer build args
ARG FRP_VERSION
ARG BUILD_DATE
ARG BASE_URL
ARG TARGET_ARCH
ARG PACKAGE_SUFFIX
ARG FRP_PACKAGE
ARG FRP_URL

WORKDIR /app

# Install dependencies and download frpc
RUN \
  set -ex && \
  echo "Installing dependencies..." && \
  apk add --no-cache wget && \
  echo "Downloading ChmlFrp from ${FRP_URL}..." && \
  wget -O "${FRP_PACKAGE}" "${FRP_URL}" && \
  tar -zxf "${FRP_PACKAGE}" && \
  cd "ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_${PACKAGE_SUFFIX}" && \
  chmod +x frpc && \
  mv frpc /app/ && \
  cd /app && \
  rm -rf "ChmlFrp-${FRP_VERSION}_${BUILD_DATE}_linux_${PACKAGE_SUFFIX}" "${FRP_PACKAGE}" && \
  echo "Build completed successfully"

# Add startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo '/app/frpc -u "${FRPC_USER}" -p "${FRPC_PROXY}"' >> /app/start.sh && \
    chmod +x /app/start.sh

# Environment variables
ENV FRPC_USER=""
ENV FRPC_PROXY=""

# Execute startup script
ENTRYPOINT ["/app/start.sh"]
