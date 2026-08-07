FROM ghcr.io/sipeed/picoclaw:launcher

# Alpine mirror (empty = use image default)
ARG ALPINE_MIRROR

ARG BASE_PKGS="bash curl git git-lfs iproute2 jq openssh-client-default vim"
ARG EXTRA_PKGS
RUN set -ex ; \
    if [ -n "$ALPINE_MIRROR" ]; then \
      MIRROR="$(echo "$ALPINE_MIRROR" | sed 's#/$##')" ; \
      sed -i "s|https\?://dl-cdn\.alpinelinux\.org/alpine|${MIRROR}/alpine|g" /etc/apk/repositories ; \
    fi ; \
    apk add --no-cache $BASE_PKGS $EXTRA_PKGS

RUN addgroup -g 1000 claw && adduser -D -u 1000 -G claw claw

COPY --chown=root:root ./cacerts/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

USER claw

#
