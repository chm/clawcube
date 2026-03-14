# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE="node:24-bookworm"
FROM ${NODE_IMAGE}

RUN corepack enable

# Extra APT packages
ARG EXTRA_PKGS="iproute2 jq"
RUN --mount=type=cache,id=openclaw-bookworm-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=openclaw-bookworm-apt-lists,target=/var/lib/apt,sharing=locked \
    set -ex ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    if [ -n "$EXTRA_PKGS" ]; then \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $EXTRA_PKGS ; \
    fi

# OpenClaw version
ARG OPENCLAW_VER="latest"
RUN --mount=type=cache,id=openclaw-pnpm-cache,target=/root,sharing=locked \
    set -ex ; \
    export INSTALL_DIR="/app" ; \
    mkdir -p "$INSTALL_DIR" ; \
    pnpm install --dir "$INSTALL_DIR" openclaw@"$OPENCLAW_VER" ; \
    ln -s node_modules/openclaw/openclaw.mjs /app/openclaw.mjs ; \
    mkdir -p /usr/local/bin ; \
    ln -s /app/openclaw.mjs /usr/local/bin/openclaw

RUN set -ex ; \
    userdel -r node ; \
    groupadd -g 1000 claw ; useradd -u 1000 -g 1000 -m claw

WORKDIR /app

USER claw

CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
