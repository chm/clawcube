# clawCube

> 多服务 Docker Compose 栈：三个 AI Agent Gateway（[OpenClaw](https://docs.openclaw.ai) / [PicoClaw](https://github.com/sipeed/picoclaw) / [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw)）+ [LiteLLM](https://github.com/BerriAI/litellm) 代理 + [Caddy](https://caddyserver.com/) 反代。

把几个 LLM / Agent 相关组件各自装进一个独立子目录，由各自的 `docker-compose.yml` 单独管理。子目录之间通过 loopback 端口 + Caddy 反代串起来。

**每个组件的镜像构建 / `.env` / 第一次使用步骤看各自子目录的 README**；本文只讲**全局视角**。

## 服务清单

| 子目录 | 默认端口 | 作用 | README |
| --- | --- | --- | --- |
| [`openclaw/`](openclaw/) | `127.0.0.1:18789` | OpenClaw AI Agent Gateway（主 runtime） | [→](openclaw/README.md) |
| [`picoclaw/`](picoclaw/) | `127.0.0.1:18800` | PicoClaw 轻量 Web Gateway | [→](picoclaw/README.md) |
| [`zeroclaw/`](zeroclaw/) | `127.0.0.1:42617` | ZeroClaw 替代 AI Agent runtime | [→](zeroclaw/README.md) |
| [`litellm/`](litellm/) | `127.0.0.1:4000` | LiteLLM 统一代理（OpenAI 兼容）+ Postgres 存储 | [→](litellm/README.md) |
| [`caddy/`](caddy/) | host `80/443` | Caddy 反代 + 内网 CA（`*.clawcube.lan`） | [→](caddy/README.md) |

三个 AI runtime **互不依赖**，按需起哪个都行。

## 拓扑

```
   *.clawcube.lan  (HTTPS, 内网 CA 自动签证书)
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│  Caddy  (network_mode: host)                     │   clawcube.lan → /www
└──────┬───────────┬───────────┬───────────┬───────┘
       │           │           │           │
       ▼           ▼           ▼           ▼
   openclaw     picoclaw     zeroclaw    litellm
    :18789       :18800       :42617      :4000  (+ Postgres :5432)
```

## 通用模式

每个子目录都遵循同样的约定：

```
<service>/
├── docker-compose.yml            # 基础 compose（命名卷 / 默认端口）
├── build/Dockerfile              # 对上游镜像的薄封装（litellm / caddy 没有 Dockerfile）
├── build/cacerts/                # 自定义 CA 证书目录（*.crt 放进去构建时自动注入 trust store）
├── .env                          # 端口 / 镜像源 / 版本
├── example/                      # 模板（实例文件全部 gitignored，按需 cp 出来）
│   ├── .env / app.env / Caddyfile / litellm_config.yaml / ...
│   └── docker-compose.override.yml
└── README.md
```

`docker-compose.override.yml` 默认在 `example/`，启用方式：

```bash
cp example/docker-compose.override.yml ./docker-compose.override.yml
docker compose up -d
```

override 常见两个用途：

- 把基础 compose 的**命名卷** 换成 **bind mount**（持久化目录落宿主）
- 加 sidecar（典型如 `openclaw` 的 `tailscale`）

## 持久化约定

所有 example override 默认假设 sibling 布局：

```
~/src/
├── clawcube/         ← 本仓库
└── data/             ← 持久化根（不在本仓库里）
    ├── openclaw/{home,log[,tailscale]}
    ├── picoclaw/home
    ├── zeroclaw/home
    ├── litellm/postgres_data
    └── caddy/{www,data,log}
```

如果 `data/` 摆在别的位置，把每份 `example/docker-compose.override.yml` 里的 `../../data/...` 改成你自己的路径即可。

## 快速启动（一次性）

```bash
# 0) 准备持久化目录
mkdir -p ../data/{openclaw/{home,log,tailscale},picoclaw/home,zeroclaw/home,litellm/postgres_data,caddy/{www,data,log}}

# 1) 按需起 AI runtime — 三选一或多选
( cd openclaw && cp -n example/app.env ./app.env \
                && cp -n example/docker-compose.override.yml ./docker-compose.override.yml \
                && docker compose up -d )
( cd picoclaw && cp -n example/docker-compose.override.yml ./docker-compose.override.yml \
                && docker compose up -d )
( cd zeroclaw && cp -n example/app.env ./app.env \
                && cp -n example/docker-compose.override.yml ./docker-compose.override.yml \
                && docker compose up -d )

# 2) LiteLLM
( cd litellm && cp -n example/.env ./.env \
               && cp -n example/litellm_config.yaml ./litellm_config.yaml \
               && cp -n example/docker-compose.override.yml ./docker-compose.override.yml \
               && docker compose up -d )

# 3) Caddy 最后（host network）
( cd caddy && cp -n example/docker-compose.override.yml ./docker-compose.override.yml \
             && docker compose up -d )
```

> Caddy 对 upstream 没硬性 health check（目标 down 它也照样起）。惯例是先用直连端口验证 runtime，再加反代。

## 访问

启动后两种方式：

- **直连** — `http://127.0.0.1:<port>`，端口见上表
- **域名** — `https://<service>.clawcube.lan`，走 Caddy HTTPS + 内网 CA

要把内网 CA 加进信任：在 Caddy 起来后从容器导出 `/data/caddy/pki/authorities/local/root.crt`，加到系统 / 浏览器的 trust store。详细步骤见 [`caddy/README.md`](caddy/README.md)。

## 停止 / 重置

每个子目录独立：

```bash
cd <service>/
docker compose down            # 停 + 删容器（命名卷不动；override 后是 bind mount，也不影响宿主目录）
docker compose down --rmi all  # 顺带删镜像
```

要彻底重置数据库：

```bash
rm -rf ../data/litellm/postgres_data
( cd litellm && docker compose up -d )
```

## 要求

- Docker Engine + Compose **v2**（命令是 `docker compose`，没连字符）
- Caddy 需要 root / 占用 `80`/`443`（host network）
- LiteLLM 自带 Postgres 16，无需宿主安装
