
ARG NODE_IMAGE="node:24-trixie"
FROM ${NODE_IMAGE}

# Debian mirror (empty = use image defaults)
ARG DEBIAN_MIRROR

# Extra APT packages
ARG BASE_PKGS="iproute2 jq"
ARG EXTRA_PKGS
RUN --mount=type=cache,id=openclaw-trixie-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=openclaw-trixie-apt-lists,target=/var/lib/apt,sharing=locked \
    set -ex ; \
    if [ -n "$DEBIAN_MIRROR" ]; then \
      MIRROR="$(echo "$DEBIAN_MIRROR" | sed 's#/$##')" ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian$|URIs: ${MIRROR}/debian|" /etc/apt/sources.list.d/debian.sources ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian-security$|URIs: ${MIRROR}/debian-security|" /etc/apt/sources.list.d/debian.sources ; \
    fi ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $BASE_PKGS $EXTRA_PKGS

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
    corepack use pnpm@latest-10 ; \
    pnpm install --dir "$INSTALL_DIR" openclaw@"$OPENCLAW_VER" ; \
    rm -fr /.pnpm-store ; \
    ln -s node_modules/openclaw/openclaw.mjs "$INSTALL_DIR"/openclaw.mjs ; \
    ln -s "$INSTALL_DIR"/openclaw.mjs /usr/local/bin/openclaw

RUN userdel -r node && groupadd -g 1000 claw && useradd -u 1000 -g 1000 -m claw

USER claw

ENV NODE_ENV="production"
ENV NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache"
ENV OPENCLAW_NO_RESPAWN=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
