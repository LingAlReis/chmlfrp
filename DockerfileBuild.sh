#!/usr/bin/env bash

set -euo pipefail

##
# ChmlFrp Docker 镜像构建脚本
#
# 特性：
# - 自动切到脚本所在目录执行（无需关心当前工作目录）
# - 通过环境变量灵活配置仓库地址 / 镜像名 / Tag / 平台
# - 支持选择是否 --push / --load、是否 --no-cache
#
# 可用环境变量（均有默认值）：
# - IMAGE_REGISTRY   默认为 harbor.5210125.xyz:12443
# - IMAGE_NAME       默认为 library/chmlfrp/frpc
# - IMAGE_TAG        默认为 latest（主 Tag）
# - BUILD_DATE_TAG   默认为当前日期，格式 yyyyMMdd
# - PLATFORMS        默认为 linux/amd64,linux/arm64,linux/arm/v7
# - DOCKERFILE       默认为 Dockerfile
# - PUSH             默认为 true（true: --push，false: --load）
# - NO_CACHE         默认为 false（true: 加上 --no-cache）
#
# 使用示例：
#   # 使用默认配置（buildx + push 到 Harbor）
#   bash DockerfileBuild.sh
#
#   # 覆盖主 Tag 和平台，并仅加载到本机（不推远程）
#   IMAGE_TAG=v1.0.0 PLATFORMS=linux/amd64 PUSH=false bash DockerfileBuild.sh
#
#   # 强制不使用缓存
#   NO_CACHE=true bash DockerfileBuild.sh
#
#   # 通过第一个参数指定 Tag
#   bash DockerfileBuild.sh v0.51.2
##

# 切换到脚本所在目录（即项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 基础配置（可通过环境变量覆盖）
IMAGE_REGISTRY="${IMAGE_REGISTRY:-harbor.5210125.xyz:12443}"
IMAGE_NAME="${IMAGE_NAME:-library/chmlfrp/frpc}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_DATE_TAG="${BUILD_DATE_TAG:-$(date +%Y%m%d)}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64,linux/arm/v7}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
PUSH="${PUSH:-true}"
NO_CACHE="${NO_CACHE:-false}"

# 允许第一个位置参数覆盖主 Tag（方便快速指定版本）
if [[ $# -ge 1 ]]; then
  IMAGE_TAG="$1"
fi

FULL_IMAGE_MAIN="${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
FULL_IMAGE_DATE="${IMAGE_REGISTRY}/${IMAGE_NAME}:${BUILD_DATE_TAG}"

echo "==> ChmlFrp Docker Build 配置"
echo "  Registry   : ${IMAGE_REGISTRY}"
echo "  Image      : ${IMAGE_NAME}"
echo "  Main Tag   : ${IMAGE_TAG}"
echo "  Date Tag   : ${BUILD_DATE_TAG}"
echo "  Platforms  : ${PLATFORMS}"
echo "  Dockerfile : ${DOCKERFILE}"
echo "  Push       : ${PUSH}"
echo "  No Cache   : ${NO_CACHE}"
echo

build_args=(buildx build --platform "${PLATFORMS}" \
  -t "${FULL_IMAGE_MAIN}" \
  -t "${FULL_IMAGE_DATE}" \
  --progress=plain -f "${DOCKERFILE}" .)

if [[ "${NO_CACHE}" == "true" ]]; then
  build_args+=(--no-cache)
fi

if [[ "${PUSH}" == "true" ]]; then
  build_args+=(--push)
else
  # 不 push 时默认 --load，方便本机调试
  build_args+=(--load)
fi

echo "==> 开始构建镜像："
echo "  - ${FULL_IMAGE_MAIN}"
echo "  - ${FULL_IMAGE_DATE}"
docker "${build_args[@]}"
echo "==> 构建完成"
