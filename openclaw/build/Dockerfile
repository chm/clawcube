
ARG NODE_IMAGE="node:24-trixie"
FROM ${NODE_IMAGE}

# Debian mirror (empty = use image defaults)
ARG DEBIAN_MIRROR

# Extra APT packages
ARG BASE_PKGS="git-lfs iproute2 iputils-ping jq unzip vim"
ARG EXTRA_PKGS
RUN set -ex ; \
    if [ -n "$DEBIAN_MIRROR" ]; then \
      MIRROR="$(echo "$DEBIAN_MIRROR" | sed 's#/$##')" ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian$|URIs: ${MIRROR}/debian|" /etc/apt/sources.list.d/debian.sources ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian-security$|URIs: ${MIRROR}/debian-security|" /etc/apt/sources.list.d/debian.sources ; \
    fi ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      $BASE_PKGS $EXTRA_PKGS ; \
    apt-get dist-clean ; \
    userdel -r node && groupadd -g 1000 claw && useradd -u 1000 -g 1000 -m claw

COPY --chown=root:root ./cacerts/* /usr/local/share/ca-certificates/
RUN update-ca-certificates
ENV NODE_EXTRA_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

ENV INSTALL_DIR="/app"
WORKDIR ${INSTALL_DIR}

RUN --mount=type=tmpfs,target=/tmp \
    corepack enable ; \
    chown claw:claw "$INSTALL_DIR" ; \
    ln -s "$INSTALL_DIR"/openclaw.mjs /usr/local/bin/openclaw

USER claw

# OpenClaw version
ARG OPENCLAW_VER="latest"
RUN set -ex ; \
    export XDG_CACHE_HOME=/tmp/xdg-cache ; \
    export XDG_CONFIG_HOME=/tmp/xdg-config ; \
    export XDG_DATA_HOME=/tmp/xdg-data ; \
    export XDG_STATE_HOME=/tmp/xdg-state; \
    export NPM_CONFIG_CACHE=/tmp/npm-cache ; \
    export PNPM_HOME=/tmp/pnpm-store ; \
    corepack use pnpm@latest-10 ; \
    pnpm install --dir "$INSTALL_DIR" openclaw@"$OPENCLAW_VER" ; \
    ln -s node_modules/openclaw/openclaw.mjs "$INSTALL_DIR"/openclaw.mjs ; \
    rm -fr /tmp/*

ENV NODE_ENV="production"
ENV NODE_COMPILE_CACHE="/var/tmp/openclaw-compile-cache"
ENV OPENCLAW_NO_RESPAWN=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
