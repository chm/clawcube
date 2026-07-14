# caddy

Caddy 反向代理 + 内部 CA 配置。

## 简介

[Caddy](https://caddyserver.com/) 跑在 `network_mode: host`，**直接占 80 / 443**。两件事：

1. **路由** — 把 `*.clawcube.lan` 反代到对应 loopback 端口
2. **内网 CA** — `pki ca clawcube` 自签短生命周期证书（默认 60 天），让 LAN 内访问 `*.clawcube.lan` 时浏览器 / 客户端信任即可跳过警告

上游镜像：`caddy:2`，**没有自定义 Dockerfile**。

## 当前路由（`Caddyfile`）

| 域名 | 后端 |
| --- | --- |
| `clawcube.lan` | `/www` 静态文件 |
| `litellm.clawcube.lan` | `127.0.0.1:4000` |
| `openclaw.clawcube.lan` | `127.0.0.1:18789` |
| `picoclaw.clawcube.lan` | `127.0.0.1:18800` |
| `zeroclaw.clawcube.lan` | `127.0.0.1:42617` |

每个站点都 `import conf-ca-clawcube` 拿内网 CA 自动签发证书。

## 目录结构

```
caddy/
├── docker-compose.yml          # 单 service：caddy（network_mode: host）
├── Caddyfile                   # 主配置：内网 CA + 路由
├── .gitignore
└── example/
    └── docker-compose.override.yml   # 持久化 config/data/log + /www
```

## 第一次使用

```bash
cd caddy

# 1) 持久化目录（override 用了 bind mount，路径必须先存在，否则 docker 自动建会变成 root，caddy 用户写不进去）
cp example/docker-compose.override.yml ./docker-compose.override.yml
mkdir -p ../data/caddy/{www,data,log}

# 2) 启动（首次会初始化 pki ca clawcube）
docker compose up -d
```

> `docker compose ps` 看到 `caddy` 状态 `Up` / `healthy`（如果加了 healthcheck）即可；`pki { ca clawcube }` 是全局 admin 配置，Caddy 启动时会先把声明的 CA 初始化好再 listen，不需要“重启一次”。

## 信任内网 CA

容器第一次启动后，CA root 在 `/data/caddy/pki/authorities/local/root.crt`（override 后落到 `../data/caddy/data/pki/authorities/local/root.crt`）：

```bash
docker compose cp caddy /data/caddy/pki/authorities/local/root.crt ./clawcube-root.crt

# Ubuntu / Debian 系统信任
sudo cp clawcube-root.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Firefox / 浏览器独立 trust store — 直接导入 .crt
```

CA 中间证书是 180 天，签发的服务证书是 60 天，过期 Caddy 会自动重签。

## Caddyfile 热更新

```bash
# 1) 编辑 Caddyfile
# 2) 校验
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
# 3) 热加载
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile --adapter=''
```

## 新增站点

在 `Caddyfile` 末尾加一段：

```caddy
mything.clawcube.lan {
  import conf-ca-clawcube
  reverse_proxy 127.0.0.1:12345
}
```

`conf-ca-clawcube` snippet 自动用内网 CA 签证书；想用别的 CA 就自己写 `tls internal` 之类。

## 持久化

| 路径 | 用途 |
| --- | --- |
| `config` | Caddy 自动管理配置 |
| `data` | Caddy 数据 / PKI / certificates |
| `log` | 访问 / 错误日志 |
| `/www` | `clawcube.lan` 静态文件根 |

`example/...override.yml` 把这几项绑到 `../../data/caddy/{www,data,log}`。

## 端口

`network_mode: host` 直接占 `80` / `443`，没有端口映射 — 跟其他 `gateway-port: 127.0.0.1:...` 的服务天然相容。
