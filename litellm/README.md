# litellm

LiteLLM 代理 + Postgres 后端的 Docker 容器配置。

## 简介

[LiteLLM](https://github.com/BerriAI/litellm) 是 OpenAI 兼容的 LLM 路由代理，统一各种 provider 的接口形态。本目录起 **两个 service**：

| service | 端口 | 说明 |
| --- | --- | --- |
| `litellm` | `127.0.0.1:4000` | 代理主进程，OpenAI 兼容 API |
| `db` | `127.0.0.1:5432` | Postgres 16，存 model / key / spend log |

上游镜像：`ghcr.io/berriai/litellm:main-stable`，自带 `litellm` CLI。

**LiteLLM 必须有 `.env` + `litellm_config.yaml` + override 才能正常启动** — 全部 `gitignore` 掉了，按需从 `example/` 拷贝。

## 目录结构

```
litellm/
├── docker-compose.yml          # 两个 service：litellm + db
├── .gitignore                  # .env / config.yaml / override 全部 ignore
└── example/
    ├── .env                    # LITELLM_MASTER_KEY 等
    ├── docker-compose.override.yml
    └── litellm_config.yaml     # 基础 config
```

## 配置

### `example/.env`

```
LITELLM_MASTER_KEY=             # 必填，OpenAI 兼容 API 的 Bearer token，例 sk-xxx

STORE_MODEL_IN_DB="True"        # model / key 允许走 DB 管理
LITELLM_DROP_PARAMS="True"     # 自动丢弃 provider 不认识的参数，避免报错
```

`docker-compose.yml` 里写死了 db 连接串 `postgresql://llmproxy:dbpassword9090@db:5432/litellm`，**改密码需同步改 compose 和 db service**，不建议改。

### `example/litellm_config.yaml`

只放了一个最小骨架（`store_model_in_db: true`）。model / router / guardrail 等规则在这里加：

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
```

### `docker-compose.override.yml`

做三件事：

1. 挂 `./litellm_config.yaml` 到容器内 `/app/config.yaml`
2. 启动参数追加 `--config=/app/config.yaml`
3. 把 postgres 数据绑到 `../../data/litellm/postgres_data`

## 第一次使用

```bash
cd litellm
cp example/.env                        ./.env
cp example/litellm_config.yaml         ./litellm_config.yaml
cp example/docker-compose.override.yml ./docker-compose.override.yml
# 编辑 .env：填 LITELLM_MASTER_KEY

docker compose up -d
```

## 验证

```bash
# 健康检查
curl http://127.0.0.1:4000/health/liveliness
curl http://127.0.0.1:4000/health/readiness

# 列模型
curl -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
     http://127.0.0.1:4000/v1/models

# 聊天
curl -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"gpt-4o","messages":[{"role":"user","content":"hi"}]}' \
     http://127.0.0.1:4000/v1/chat/completions
```

## 与 clawCube 其他服务集成

- OpenClaw `example/app.env` 里有 `LITELLM_API_KEY=...`，配合 `example/app.env` 中的注释行解开即可把 OpenClaw 的请求路由到本 LiteLLM
- Caddy 的 `litellm.clawcube.lan` 反代 `127.0.0.1:4000`，让 LAN 内其他客户端通过内网 CA 证书访问

## 持久化

`postgres_data`（命名卷 `litellm_postgres_data` / override 后换成 `../data/litellm/postgres_data`）— Postgres 数据。

> 重启 litellm 容器不会影响 `db` 容器里的数据；只有 `docker compose down -v` 会丢。
