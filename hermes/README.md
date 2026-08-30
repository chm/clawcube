# hermes

Hermes Agent 的 Docker 容器配置。

## 简介

[Hermes Agent](https://github.com/NousResearch/hermes-agent) 是 NousResearch 出品的 AI Agent Gateway，自带 Dashboard（`9119`）和 Gateway API（`8642`）。

本目录对上游镜像 `docker.io/nousresearch/hermes-agent:v${HERMES_VER}`（`debian:13` 系 base）做薄封装：

- 换 APT 源（`DEBIAN_MIRROR`）+ 系统升级
- 装基础包：`git-lfs iproute2 iputils-ping jq unzip vim` + `EXTRA_PKGS`
- 构建时支持自定义 CA 证书（放入 `build/cacerts/` 目录，注入系统 trust store + `NODE_EXTRA_CA_CERTS`）

## 目录结构

```
hermes/
├── docker-compose.yml          # 基础 compose：hermes gateway
├── build/Dockerfile            # 对上游镜像的薄封装
├── build/cacerts/              # 自定义 CA 证书目录（*.crt 放进去构建时自动注入 trust store）
├── .env                        # 端口 / 镜像源 / 版本
├── .gitignore
├── hermes                      # CLI 包装脚本（预留）
└── example/
    ├── app.env                 # 运行时 secret / provider key
    └── docker-compose.override.yml
```

## 配置

### `.env`（基础 / 构建期）

| 变量 | 作用 | 备注 |
| --- | --- | --- |
| `HERMES_VER` | 上游镜像版本 tag（不含 `v` 前缀） | 默认 `2026.8.27` |
| `HERMES_UID` / `HERMES_GID` | 容器内运行用户 | 默认 `1000` |
| `HERMES_PORT` | host 绑定地址端口 | 默认 `127.0.0.1:9119` |
| `DEBIAN_MIRROR` | Debian APT 镜像 | 留空用默认 |
| `EXTRA_PKGS` | 额外 APT 包 | 默认 `eza ripgrep` |

### 自定义 CA 证书

将内部 CA 的 `.crt` 文件放入 `build/cacerts/` 目录（已 gitignore，只留 `.keep` 占位），构建时会自动拷入 `/usr/local/share/ca-certificates/` 并执行 `update-ca-certificates`。同时设置 `NODE_EXTRA_CA_CERTS` 使 Node.js 也信任该 CA。

```bash
cp /path/to/internal-ca.crt hermes/build/cacerts/
cd hermes && docker compose build hermes
```

### `app.env`（运行时 secret）

由 compose 用 `env_file` 加载：

- `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` / `PASSWORD` — Dashboard 认证
- `API_SERVER_KEY` — Gateway API key
- `GLM_API_KEY` — bigmodel.cn
- `STEPFUN_API_KEY` — platform.stepfun.com
- 其他 Hermes 支持的 provider key（看上游 `.env.example`）

> app.env **不**提交；按需从 `example/app.env` 拷出后填值。

## 第一次使用

```bash
cd hermes

# 1) 拷贝示例配置
cp example/app.env                       ./app.env
cp example/docker-compose.override.yml   ./docker-compose.override.yml
# 编辑 app.env 填 API key

# 2) 构建 + 启动（首次按 build/Dockerfile 构建镜像）
docker compose up -d

# 3) 验证
curl http://127.0.0.1:9119
```

改了 `build/Dockerfile` 或 `.env` 后重建：

```bash
docker compose build hermes
docker compose up -d
```

## 端口

| 端口 | 说明 |
| --- | --- |
| `9119` | Dashboard（`HERMES_DASHBOARD=1` 时启用） |
| `8642` | Gateway API（默认未映射，Caddy 反代走 host 网络） |

## 与 clawCube 其他服务集成

- Caddy 的 `hermes.clawcube.lan` 反代 `127.0.0.1:9119`，让 LAN 内其他客户端通过内网 CA 证书访问

## 持久化

| 容器路径 | 用途 |
| --- | --- |
| `/opt/data` | Hermes 主数据目录（配置 / workspace / 记忆） |

`example/docker-compose.override.yml` 默认挂到 sibling 目录 `../../data/hermes/data`。

> 重启容器不影响数据；只有 `docker compose down -v`（命名卷模式）或手动删除 bind mount 目录才会丢。
