FROM ghcr.io/sipeed/picoclaw:launcher

# Alpine mirror (empty = use image default)
ARG ALPINE_MIRROR

ARG BASE_PKGS="bash curl git iproute2 jq openssh-client-default"
ARG EXTRA_PKGS
RUN set -ex ; \
    if [ -n "$ALPINE_MIRROR" ]; then \
      MIRROR="$(echo "$ALPINE_MIRROR" | sed 's#/$##')" ; \
      sed -i "s|https\?://dl-cdn\.alpinelinux\.org/alpine|${MIRROR}/alpine|g" /etc/apk/repositories ; \
    fi ; \
    apk add --no-cache $BASE_PKGS $EXTRA_PKGS

RUN addgroup -g 1000 claw && adduser -D -u 1000 -G claw claw

USER claw

#
