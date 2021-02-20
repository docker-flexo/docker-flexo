ARG FLEXO_VERSION=1.1.0

# A separate stage is used only for fetching the dependencies:
# This is done so that we can use cargo's --offline mode in a subsequent stage,
# as a workaround for this bug: https://github.com/docker/buildx/issues/395
FROM --platform=$BUILDPLATFORM rust:1.49.0-buster as fetch

ARG FLEXO_VERSION

WORKDIR /tmp

RUN mkdir /tmp/flexo_sources

RUN wget -q https://github.com/nroi/flexo/archive/$FLEXO_VERSION.tar.gz && \
    tar xf $FLEXO_VERSION.tar.gz

RUN cd flexo-$FLEXO_VERSION/flexo && \
    cargo vendor && \
    cd .. && \
    cp -r flexo /tmp/flexo_sources/

FROM rust:1.49.0-buster as build

COPY --from=fetch /tmp/flexo_sources/ /tmp/flexo_sources

RUN mkdir /tmp/flexo_sources/flexo/.cargo

COPY cargo-config /tmp/flexo_sources/flexo/.cargo/config

RUN cd /tmp/flexo_sources/flexo && \
    cargo build --release --offline && \
    cp target/release/flexo /tmp/flexo

FROM debian:buster-slim

EXPOSE 7878

RUN apt-get update && \
    apt-get install -y curl

RUN mkdir -p /var/cache/flexo/pkg && \
    mkdir /var/cache/flexo/state && \
    mkdir /etc/flexo && \
    mkdir -p /var/cache/flexo/pkg/community/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/community-staging/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/community-testing/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/core/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/extra/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/gnome-unstable/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/kde-unstable/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/multilib/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/multilib-testing/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/staging/os/x86_64 && \
    mkdir -p /var/cache/flexo/pkg/testing/os/x86_64

ENV FLEXO_CACHE_DIRECTORY="/var/cache/flexo/pkg" \
    FLEXO_LOW_SPEED_LIMIT=128000 \
    FLEXO_LOW_SPEED_TIME_SECS=3 \
    FLEXO_MIRRORLIST_FALLBACK_FILE="/var/cache/flexo/state/mirrorlist" \
    FLEXO_PORT=7878 \
    FLEXO_MIRROR_SELECTION_METHOD="auto" \
    FLEXO_MIRRORS_PREDEFINED=[] \
    FLEXO_MIRRORS_BLACKLIST=[] \
    FLEXO_MIRRORS_AUTO_HTTPS_REQUIRED=true \
    FLEXO_MIRRORS_AUTO_IPV4=true \
    FLEXO_MIRRORS_AUTO_IPV6=false \
    FLEXO_MIRRORS_AUTO_MAX_SCORE=2.5 \
    FLEXO_MIRRORS_AUTO_NUM_MIRRORS=8 \
    FLEXO_MIRRORS_AUTO_MIRRORS_RANDOM_OR_SORT="sort" \
    FLEXO_MIRRORS_AUTO_TIMEOUT=350

ENV RUST_LOG="info"

COPY --from=build /tmp/flexo /usr/bin/flexo

ENTRYPOINT /usr/bin/flexo
