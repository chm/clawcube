FROM ghcr.io/sipeed/picoclaw:launcher

ARG BASE_PKGS="bash iproute2 jq"
ARG EXTRA_PKGS

RUN set -ex ; \
    addgroup -g 1000 pico ; \
    adduser -D -u 1000 -G pico pico ; \
    apk add --no-cache $BASE_PKGS $EXTRA_PKGS

USER pico

#
