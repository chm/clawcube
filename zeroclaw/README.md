# zeroclaw

ZeroClaw 的 Docker 容器配置。

## 简介

ZeroClaw 由 zeroclaw-labs 出品（[github.com/zeroclaw-labs/zeroclaw](https://github.com/zeroclaw-labs/zeroclaw)）。

本目录是对上游 Debian 镜像的薄封装：

- 基础镜像：`ghcr.io/zeroclaw-labs/zeroclaw[:TAG]-debian`
- 装 `iproute2 jq iputils-ping unzip` + `EXTRA_PKGS`
- 切到 uid/gid=1000 的 `claw` 用户（`OPENCLAW_HOME`-style：HOME=/home/claw，DATA_DIR=/home/claw/data）
- 构建时支持自定义 CA 证书（放入 `build/cacerts/` 目录）

镜像 tag 由 `ZEROCLAW_VER` 控制；不指定时取 `:-latest`，需要锁版本时显式填。

## 目录结构

```
zeroclaw/
├── docker-compose.yml          # 单 service：zeroclaw
├── build/Dockerfile            # 基于 zeroclaw debian tag 的薄封装
├── .env                        # 端口 / 镜像源 / UID:GID
├── .gitignore
└── example/
    ├── app.env                 # 运行时变量（TZ 等）
    └── docker-compose.override.yml
```

## 配置（`.env`）

| 变量 | 作用 | 备注 |
| --- | --- | --- |
| `ZEROCLAW_VER` | 镜像 tag（不带 `-debian` 后缀，compose 帮你拼） | 默认 `latest` |
| `ZEROCLAW_PORT` | host 端口映射 | 默认 `127.0.0.1:42617` |
| `ZEROCLAW_UID` / `ZEROCLAW_GID` | 容器内用户 | 默认 `1000` |
| `DEBIAN_MIRROR` | Debian APT 镜像 | 留空用默认 |
| `EXTRA_PKGS` | 额外包 | 默认 `exa ripgrep` |

### 自定义 CA 证书

将内部 CA 的 `.crt` 文件放入 `build/cacerts/` 目录（已 gitignore，只留 `.keep` 占位），构建时会自动拷入 `/usr/local/share/ca-certificates/` 并执行 `update-ca-certificates`。

```bash
cp /path/to/internal-ca.crt zeroclaw/build/cacerts/
cd zeroclaw && docker compose build
```

### `app.env`（运行时）

只放容器内运行时变量，示例里只有 `TZ=Asia/Shanghai`。其他 ZeroClaw 配置（provider / channel / key）走 `ZEROCLAW_*` env。

## 第一次使用

```bash
cd zeroclaw
cp example/app.env                       ./app.env
cp example/docker-compose.override.yml   ./docker-compose.override.yml
docker compose up -d zeroclaw
```

Healthcheck 用上游命令：`zeroclaw status --format=exit-code`。

改 `build/Dockerfile` 或 `.env` 后重建：

```bash
docker compose build zeroclaw
docker compose up -d zeroclaw
```

容器内的 zeroclaw CLI：

```bash
docker compose exec zeroclaw zeroclaw --help
docker compose exec zeroclaw zeroclaw status
```

## 端口

| 端口 | 说明 |
| --- | --- |
| `42617` | ZeroClaw gateway（默认 expose，`network_mode` 与 picoclaw 一致走 host 网络也 OK） |

## 持久化

`/home/claw/data` — ZeroClaw 数据目录。`example/...override.yml` 默认挂到 `../../data/zeroclaw/home`。
