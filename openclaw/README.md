# openclaw

OpenClaw 的 Docker 容器配置 — 在 clawCube 中充当 AI Agent Gateway。

## 简介

OpenClaw（`openclaw`）是一个常驻 AI Agent Gateway。本目录用同一个镜像起两个 service：

| service | profile | 作用 |
| --- | --- | --- |
| `gateway` | （默认） | 守护进程，监听 `0.0.0.0:18789` |
| `cli` | `cli` | CLI 控制面，与 gateway 共享网络栈（`network_mode: service:gateway`） |

CLI 通过仓库根的 `./openclaw` wrapper 调用，等价于 `docker compose run --rm cli <args>`。

镜像从零构建：`build/Dockerfile` 基于 `node:24-trixie`，用 pnpm 拉取 `openclaw@${OPENCLAW_VER}`（默认 `2026.7.1`），并安装 `iproute2 jq iputils-ping unzip` + `EXTRA_PKGS`。构建时支持自定义 CA 证书（放入 `build/cacerts/` 目录），会注入系统 trust store 并设置 `NODE_EXTRA_CA_CERTS`。

## 目录结构

```
openclaw/
├── docker-compose.yml          # 基础 compose：gateway + cli
├── build/Dockerfile            # 从 node:24-trixie 构建镜像
├── .env                        # 当前生效的端口 / 镜像源（gitignored 的副本例外）
├── .gitignore
├── openclaw                    # CLI 包装脚本，调用 `docker compose run --rm cli ...`
└── example/
    ├── app.env                 # 运行时 secret / channel / provider key
    └── docker-compose.override.yml   # 持久化卷 + 可选 Tailscale sidecar
```

## 配置

### `.env`（基础 / 构建期）

| 变量 | 作用 | 备注 |
| --- | --- | --- |
| `OPENCLAW_VER` | OpenClaw npm 版本 | 默认 `2026.7.1` |
| `OPENCLAW_TZ` | 容器时区 | 已默认 `Asia/Shanghai` |
| `OPENCLAW_GATEWAY_PORT` | host 绑定地址端口 | 默认 `127.0.0.1:18789` |
| `OPENCLAW_GATEWAY_BIND` | bind 模式 | 默认 LAN 绑定可放开 |
| `OPENCLAW_BRIDGE_PORT` | bridge 端口 | 默认注释，按需打开 |
| `DEBIAN_MIRROR` | Debian APT 镜像 | 留空用默认 |
| `EXTRA_PKGS` | 额外 APT 包 | 默认 `eza ripgrep` |

### 自定义 CA 证书

将内部 CA 的 `.crt` 文件放入 `build/cacerts/` 目录（已 gitignore，只留 `.keep` 占位），构建时会自动拷入 `/usr/local/share/ca-certificates/` 并执行 `update-ca-certificates`。OpenClaw 镜像额外设置 `NODE_EXTRA_CA_CERTS` 使 Node.js 信任该 CA——用于连接自签 HTTPS 的 LLM endpoint / MCP server 等场景。

```bash
cp /path/to/internal-ca.crt openclaw/build/cacerts/
cd openclaw && docker compose build gateway
```

### `app.env`（运行时 secret）

由 compose 用 `env_file` 加载，`OPENCLAW_*` 字段之外的 key 走对应 provider / channel：

- `OPENCLAW_GATEWAY_TOKEN` — gateway 访问 token
- `OPENCLAW_DISABLE_BONJOUR=1` — 关闭 LAN mDNS 广播
- `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1` — 允许非加密 WS（本地调试）
- Provider / channel key：`CLAUDE_AI_SESSION_KEY`、`OPENROUTER_API_KEY`、`LITELLM_API_KEY`、`BRAVE_API_KEY`、`FEISHU_APP_ID` / `FEISHU_APP_SECRET` …

> app.env **不**提交；按需从 `example/app.env` 拷出后填值。

## 第一次使用

```bash
cd openclaw

# 1) 拷贝示例配置（按需）
cp example/app.env                       ./app.env
cp example/docker-compose.override.yml   ./docker-compose.override.yml
# 编辑 app.env 填 token / API key
# 编辑 override：把 `../../data/openclaw/...` 改成你想要的宿主路径

# 2) 启动 gateway（首次会按 build/Dockerfile 构建镜像）
docker compose up -d gateway

# 3) wrapper 跑 CLI
./openclaw status
./openclaw chat
```

CLI 与 gateway 共享 home/log volume，并在同一网络栈里 — 容器内 localhost 直通 gateway。

后续改了 `build/Dockerfile` 或 `.env` 想重建时：

```bash
docker compose build gateway
docker compose up -d gateway
```

## CLI 用法（用 wrapper）

```bash
./openclaw status
./openclaw chat
./openclaw models list
./openclaw cron list
./openclaw --help
```

> CLI 容器是 `profile: ["cli"]` 的“按需”容器，不要 `docker compose up cli`，用 wrapper。

## 端口

| 端口 | 说明 |
| --- | --- |
| `18789` | Gateway HTTP / WebSocket API（默认 expose） |
| `18790` | Bridge（默认关闭，需要时取消 compose 中的注释） |

## 持久化

| 容器路径 | 用途 |
| --- | --- |
| `/home/claw` | OpenClaw 配置 / workspace / 记忆 |
| `/tmp/openclaw` | 日志 |
| `/var/lib/tailscale` | （override 才挂）Tailscale 状态目录 |

`example/docker-compose.override.yml` 默认挂到 sibling 目录 `../../data/openclaw/{home,log,tailscale}`。

## Tailscale sidecar

override 里的 `tailscale` service 与 gateway 共享网络栈（`network_mode: service:gateway`），`container_name` 自动取 `${COMPOSE_PROJECT_NAME}-tailscale` 方便其他容器 / DNS 引用。

## 健康检查

容器内置 healthcheck（`wget /healthz`），compose `restart: unless-stopped` 会自动拉起；Tailscale sidecar 在 override 里 opt-in。
