FROM ghcr.io/sipeed/picoclaw:launcher

# Alpine mirror (empty = use image default)
ARG ALPINE_MIRROR

ARG BASE_PKGS="bash iproute2 jq"
ARG EXTRA_PKGS

RUN set -ex ; \
    addgroup -g 1000 pico ; \
    adduser -D -u 1000 -G pico pico ; \
    if [ -n "$ALPINE_MIRROR" ]; then \
      MIRROR="$(echo "$ALPINE_MIRROR" | sed 's#/$##')" ; \
      sed -i "s|https\?://dl-cdn\.alpinelinux\.org/alpine|${MIRROR}/alpine|g" /etc/apk/repositories ; \
    fi ; \
    apk add --no-cache $BASE_PKGS $EXTRA_PKGS

USER pico

#
