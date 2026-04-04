# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE="node:24-trixie"
FROM ${NODE_IMAGE}

RUN corepack enable

# Extra APT packages
ARG EXTRA_PKGS="iproute2 jq"
ENV INSTALL_DIR="/app"
RUN --mount=type=cache,id=openclaw-trixie-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=openclaw-trixie-apt-lists,target=/var/lib/apt,sharing=locked \
    set -ex ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    if [ -n "$EXTRA_PKGS" ]; then \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $EXTRA_PKGS ; \
    fi ; \
    userdel -r node ; \
    groupadd -g 1000 claw ; useradd -u 1000 -g 1000 -m claw ; \
    mkdir -p "$INSTALL_DIR"

# OpenClaw version
ARG OPENCLAW_VER="latest"
RUN --mount=type=cache,id=openclaw-pnpm-cache,target=/root,sharing=locked \
    set -ex ; \
    pnpm install --dir "$INSTALL_DIR" openclaw@"$OPENCLAW_VER" ; \
    ln -s node_modules/openclaw/openclaw.mjs /app/openclaw.mjs ; \
    mkdir -p /usr/local/bin ; \
    ln -s /app/openclaw.mjs /usr/local/bin/openclaw

WORKDIR /app

USER claw

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
