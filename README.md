# ChmlFrp

## 1. 项目介绍

本项目为 **ChmlFrp** 客户端的 Docker 化方案，用于在容器中运行 `frpc`，通过环境变量配置用户与代理 ID，便于在多架构（amd64 / arm64 / armv7）环境下构建与部署。镜像基于 Alpine，体积小，适合内网穿透、EasyTier、WireGuard 等隧道场景。

## 2. 项目文件说明

| 文件 | 说明 |
|------|------|
| `Dockerfile` | 多架构镜像构建定义，从指定地址下载 ChmlFrp 并安装 `frpc`，通过 `FRPC_USER`、`FRPC_PROXY` 启动。 |
| `Dockerbuild.sh` | 推荐使用的构建脚本：自动切到项目目录、支持环境变量配置仓库/镜像名/Tag/平台、可选 push 或 load、可选无缓存构建。 |
| `DockerfilebBuild.sh` | 通用 Docker 构建脚本模板，可被其他项目复用；本项目中以 `Dockerbuild.sh` 为 ChmlFrp 专用脚本。 |
| `docker-compose.yml` | 编排示例：定义多个 frpc 服务（如 EasyTier、WireGuard），使用 host 网络、健康检查及外部网络。 |

目录结构示例：

```
chmlfrp/
├── Dockerfile
├── Dockerbuild.sh
├── DockerfilebBuild.sh
├── docker-compose.yml
└── README.md
```

## 3. 项目使用说明

运行容器时需通过环境变量传入 ChmlFrp 的用户标识与代理 ID：

- **`FRPC_USER`**：ChmlFrp 用户凭证（由服务端或控制台提供）。
- **`FRPC_PROXY`**：代理 ID，对应要使用的隧道/代理编号。

容器内通过 `/app/start.sh` 执行：`/app/frpc -u "${FRPC_USER}" -p "${FRPC_PROXY}"`。  
如需时区与语言，可增加 `TZ=Asia/Shanghai`、`LANG=en_US.UTF-8` 等环境变量。

## 4. 项目构建

在项目根目录执行构建脚本即可（脚本会自动 `cd` 到自身所在目录）：

```bash
# 使用默认配置：多架构构建并 push 到 Harbor
bash Dockerbuild.sh
```

默认行为：

- 镜像：`harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest`（以及日期 Tag）
- 平台：`linux/amd64,linux/arm64,linux/arm/v7`
- 使用 `Dockerfile`，带 `--push`

常用自定义方式：

```bash
# 仅构建 amd64 并加载到本机（不推送）
PLATFORMS=linux/amd64 PUSH=false bash Dockerbuild.sh

# 指定 Tag 并禁用缓存
IMAGE_TAG=v0.51.2 NO_CACHE=true bash Dockerbuild.sh

# 或通过第一个参数传 Tag
bash Dockerbuild.sh v0.51.2
```

更多环境变量见 `Dockerbuild.sh` 头部注释（如 `IMAGE_REGISTRY`、`IMAGE_NAME`、`BUILD_DATE_TAG`、`DOCKERFILE` 等）。

## 5. 项目部署

### 5.1 使用 Docker 单容器运行

先构建或拉取镜像，再通过 `docker run` 传入环境变量：

```bash
docker run -d \
  --name chmlfrpc \
  --network host \
  -e TZ=Asia/Shanghai \
  -e LANG=en_US.UTF-8 \
  -e FRPC_USER=你的用户凭证 \
  -e FRPC_PROXY=你的代理ID \
  --restart always \
  harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
```

`--network host` 使 frpc 使用宿主机网络，便于暴露端口或组网。

### 5.2 使用 Docker Compose 编排

推荐使用 `docker-compose.yml` 管理一个或多个 frpc 实例（例如不同代理 ID 或不同用途）。完整示例见下，两个服务分别用于 EasyTier（端口 11010）与 WireGuard（51820/udp），使用 host 网络与健康检查。

**准备网络（若使用 external 网络）：**

```bash
docker network create local
```

**`docker-compose.yml` 完整示例（请将 `FRPC_USER`、`FRPC_PROXY` 改为实际值）：**

```yaml
services:
  # chmlfrpceasytier 11010
  chmlfrpceasytier:
    image: harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
    container_name: chmlfrpceasytier
    hostname: chmlfrpceasytier
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - LANG=en_US.UTF-8
      - FRPC_USER=xxxxxx
      - FRPC_PROXY=xxxxxx
    restart: always
    healthcheck:
      test: ["CMD", "pgrep", "-f", "frpc"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s

  # chmlfrpcwireguard 51820/udp
  chmlfrpcwireguard:
    image: harbor.5210125.xyz:12443/library/chmlfrp/frpc:latest
    container_name: chmlfrpcwireguard
    hostname: chmlfrpcwireguard
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - LANG=en_US.UTF-8
      - FRPC_USER=xxxxxx
      - FRPC_PROXY=xxxxxx
    restart: always
    healthcheck:
      test: ["CMD", "pgrep", "-f", "frpc"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s

networks:
  local:
    external: true
```

**说明：**

- **chmlfrpceasytier**：用于 EasyTier（端口 11010 等），将 `FRPC_USER`、`FRPC_PROXY` 改为该隧道对应的凭证与代理 ID。
- **chmlfrpcwireguard**：用于 WireGuard（51820/udp），同样修改上述两个环境变量。
- 两服务均使用 `network_mode: host`、`restart: always`，健康检查通过 `pgrep -f frpc` 判断 frpc 是否在运行。
- `networks.local.external: true` 表示使用已存在的 `local` 网络，需先执行 `docker network create local`；若仅用 host 模式可删掉 `networks` 段或按需简化。

**启动：**

```bash
docker compose up -d
```

根据实际需求复制或删减服务块，并修改各服务中的 `FRPC_USER`、`FRPC_PROXY` 即可扩展更多 frpc 实例。

---

以上从项目介绍、文件说明、使用方式、构建到部署（Docker 与 Docker Compose）已覆盖完整流程，可直接按顺序操作。
