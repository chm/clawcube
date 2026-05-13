# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE="node:24-trixie"
FROM ${NODE_IMAGE}

# Debian mirror (empty = use image defaults)
ARG DEBIAN_MIRROR=""

# Extra APT packages
ARG EXTRA_PKGS="iproute2 jq"
RUN --mount=type=cache,id=openclaw-trixie-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=openclaw-trixie-apt-lists,target=/var/lib/apt,sharing=locked \
    set -ex ; \
    userdel -r node ; groupadd -g 1000 claw ; useradd -u 1000 -g 1000 -m claw ; \
    if [ -n "$DEBIAN_MIRROR" ]; then \
      MIRROR="$(echo "$DEBIAN_MIRROR" | sed 's#/$##')" ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian$|URIs: ${MIRROR}/debian|" /etc/apt/sources.list.d/debian.sources ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian-security$|URIs: ${MIRROR}/debian-security|" /etc/apt/sources.list.d/debian.sources ; \
    fi ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    if [ -n "$EXTRA_PKGS" ]; then \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $EXTRA_PKGS ; \
    fi

ENV INSTALL_DIR="/app"
WORKDIR ${INSTALL_DIR}

RUN --mount=type=cache,id=openclaw-tmp-cache,target=/tmp,sharing=locked \
    corepack enable

# OpenClaw version
ARG OPENCLAW_VER="latest"
RUN --mount=type=cache,id=openclaw-pnpm-cache,target=/root,sharing=locked \
    --mount=type=cache,id=openclaw-tmp-cache,target=/tmp,sharing=locked \
    set -ex ; \
    export PNPM_HOME=/.pnpm-store ; \
    corepack use pnpm@10.33.2 ; \
    pnpm install --dir "$INSTALL_DIR" openclaw@"$OPENCLAW_VER" ; \
    rm -fr /.pnpm-store ; \
    ln -s node_modules/openclaw/openclaw.mjs "$INSTALL_DIR"/openclaw.mjs ; \
    ln -s "$INSTALL_DIR"/openclaw.mjs /usr/local/bin/openclaw

USER claw

ENV NODE_ENV="production"
ENV NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache"
ENV OPENCLAW_NO_RESPAWN=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
