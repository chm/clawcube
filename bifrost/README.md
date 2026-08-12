# bifrost

Bifrost LLM 网关的 Docker 容器配置。

## 简介

[Bifrost](https://github.com/maximhq/bifrost) 是高性能 LLM 请求路由/代理，支持多 provider 池化、自动重试、fallback、日志追踪。兼容 OpenAI API 格式。

上游镜像：`maximhq/bifrost`。

**Bifrost 必须有 `app.env` + `config.json` + override 才能正常启动** — 全部 `gitignore` 掉了，按需从 `example/` 拷贝。

## 目录结构

```
bifrost/
├── .env                          # 版本 / 端口（tracked）
├── docker-compose.yml            # 基础 compose
├── .gitignore                    # app.env / config.json / override 全部 ignore
└── example/
    ├── app.env                   # 敏感配置模板
    ├── config.json               # bifrost 主配置
    └── docker-compose.override.yml
```

## 配置

### `.env`（tracked）

```
BIFROST_VER="latest"              # 镜像版本
BIFROST_PORT="0.0.0.0:4001"       # 宿主端口绑定
LOG_LEVEL="info"                  # debug / info / warn / error
LOG_STYLE="json"                  # json / text
```

### `example/app.env`

bifrost 管理后台认证凭据，`config.json` 的 `auth_config` 通过 `env.` 前缀引用这里的变量：

```
BIFROST_ADMIN_USERNAME=admin    # 管理员用户名
BIFROST_ADMIN_PASSWORD=         # 必填，管理后台登录密码
```

### `example/config.json`

bifrost 主配置：

- `auth_config` — 启用管理后台认证，用户名/密码从 `app.env` 读取（`env.BIFROST_ADMIN_USERNAME` / `env.BIFROST_ADMIN_PASSWORD`）
- `config_store` / `logs_store` — SQLite 持久化路径（config.db / logs.db）

按需添加 provider、model pool、retry 策略等。详见 [Bifrost 官方文档](https://github.com/maximhq/bifrost)。

### `example/docker-compose.override.yml`

做两件事：

1. 把 `./config.json` 挂到 `/app/data/config.json`
2. 数据目录绑到 `../../data/bifrost/data`

## 第一次使用

```bash
cd bifrost
cp example/app.env                   ./app.env
cp example/config.json               ./config.json
cp example/docker-compose.override.yml ./docker-compose.override.yml
# 编辑 app.env：填 BIFROST_ADMIN_PASSWORD

docker compose up -d
```

## 验证

```bash
# 健康检查
curl http://127.0.0.1:4001/health

# OpenAI 兼容 chat（bifrost 配置了 provider 后）
curl -H "Content-Type: application/json" \
     -d '{"model":"gpt-4o","messages":[{"role":"user","content":"hi"}]}' \
     http://127.0.0.1:4001/v1/chat/completions
```

## 与 clawCube 其他服务集成

- Caddy 的 `bifrost.clawcube.lan` 反代 `127.0.0.1:4001`，让 LAN 内其他客户端通过内网 CA 证书访问

## 持久化

`data`（命名卷 `bifrost_data` / override 后换成 `../../data/bifrost/data`）— 包含 SQLite 数据库（config.db、logs.db）等运行时数据。

> 重启容器不影响数据；只有 `docker compose down -v`（命名卷模式）或手动删除 bind mount 目录才会丢。
