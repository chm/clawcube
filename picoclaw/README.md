# picoclaw

PicoClaw 的 Docker 容器配置。

## 简介

PicoClaw 由 Sipeed 出品（[github.com/sipeed/picoclaw](https://github.com/sipeed/picoclaw)），定位是轻量 AI Agent Gateway / Web UI。

本目录只是对官方 launcher 镜像的薄封装：

- 基础镜像：`ghcr.io/sipeed/picoclaw:launcher`
- 装基础包：`bash curl git iproute2 jq openssh-client-default` + `EXTRA_PKGS`
- 创建 uid/gid=1000 的 `claw` 用户，运行时切到这个非 root 用户
- 构建时支持自定义 CA 证书（放入 `build/cacerts/` 目录）

## 目录结构

```
picoclaw/
├── docker-compose.yml          # 单 service：picoclaw
├── build/Dockerfile            # 基于 upstream launcher 的薄封装
├── .env                        # 端口 / 镜像源
├── .gitignore
└── example/
    └── docker-compose.override.yml   # 持久化卷
```

## 配置（`.env`）

| 变量 | 作用 | 备注 |
| --- | --- | --- |
| `PICOCLAW_WEB_PORT` | Web UI host 端口 | 默认 `127.0.0.1:18800` |
| `PICOCLAW_GW_PORT` | Gateway 端口（内部 18790） | 默认未映射，按需打开 |
| `ALPINE_MIRROR` | APK 镜像源 | 留空用 `dl-cdn.alpinelinux.org` |
| `EXTRA_PKGS` | 额外 APK 包 | 默认 `python3 uv nodejs npm` |

## 第一次使用

```bash
cd picoclaw
cp example/docker-compose.override.yml ./docker-compose.override.yml
docker compose up -d picoclaw
```

启动后访问 `http://127.0.0.1:18800`。

> launcher 自带 health endpoint `http://localhost:18790/health`，本 compose 的 healthcheck 就是 wget 它。

### 自定义 CA 证书

将内部 CA 的 `.crt` 文件放入 `build/cacerts/` 目录（已 gitignore，只留 `.keep` 占位），构建时会自动拷入 `/usr/local/share/ca-certificates/` 并执行 `update-ca-certificates`。

```bash
cp /path/to/internal-ca.crt picoclaw/build/cacerts/
cd picoclaw && docker compose build
```

改 `build/Dockerfile` 或 `.env` 后重建：

```bash
docker compose build picoclaw
docker compose up -d picoclaw
```

## 端口

| 端口 | 说明 |
| --- | --- |
| `18800` | Web UI（默认 expose） |
| `18790` | Gateway API（默认未映射，caddy route 可走 host 网络） |

## 持久化

`/home/claw` — PicoClaw 主目录（配置 / 数据 / workspace）。`example/...override.yml` 默认挂到 `../../data/picoclaw/home`。
