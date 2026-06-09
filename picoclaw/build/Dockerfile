FROM ghcr.io/sipeed/picoclaw:launcher

ARG EXTRA_PKGS="iproute2 jq"
RUN set -ex ; \
    if [ -n "$EXTRA_PKGS" ]; then \
      apk add --no-cache $EXTRA_PKGS ; \
    fi

#
