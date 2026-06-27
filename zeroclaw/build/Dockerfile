
ARG ZEROCLAW_VER
FROM ghcr.io/zeroclaw-labs/zeroclaw:${ZEROCLAW_VER:-}debian

USER root

# Debian mirror (empty = use image defaults)
ARG DEBIAN_MIRROR

# Extra APT packages
ARG BASE_PKGS="iproute2 jq"
ARG EXTRA_PKGS
RUN --mount=type=cache,id=zeroclaw-bookworm-apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=zeroclaw-bookworm-apt-lists,target=/var/lib/apt,sharing=locked \
    set -ex ; \
    if [ -n "$DEBIAN_MIRROR" ]; then \
      MIRROR="$(echo "$DEBIAN_MIRROR" | sed 's#/$##')" ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian$|URIs: ${MIRROR}/debian|" /etc/apt/sources.list.d/debian.sources ; \
      sed -i -E "s|URIs: http://deb\.debian\.org/debian-security$|URIs: ${MIRROR}/debian-security|" /etc/apt/sources.list.d/debian.sources ; \
    fi ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $BASE_PKGS $EXTRA_PKGS

# Add User
ARG ZEROCLAW_UID
ARG ZEROCLAW_GID
RUN groupadd -g ${ZEROCLAW_GID} claw && useradd -u ${ZEROCLAW_UID} -g ${ZEROCLAW_GID} -m claw

USER claw
