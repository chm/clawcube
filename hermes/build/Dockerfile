ARG HERMES_IMAGE="docker.io/nousresearch/hermes-agent"
ARG HERMES_VER
FROM ${HERMES_IMAGE}:v${HERMES_VER}

# Debian mirror (empty = use image defaults)
ARG DEBIAN_MIRROR

# Extra APT packages
ARG BASE_PKGS="git-lfs iproute2 iputils-ping jq unzip vim"
ARG EXTRA_PKGS

USER root

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
    apt-get dist-clean

COPY --chown=root:root ./cacerts/* /usr/local/share/ca-certificates/
RUN update-ca-certificates
ENV NODE_EXTRA_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

#
