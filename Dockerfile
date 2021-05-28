ARG FLEXO_VERSION=1.3.2

# A separate stage is used only for fetching the dependencies:
# This is done so that we can use cargo's --offline mode in a subsequent stage,
# as a workaround for this bug: https://github.com/docker/buildx/issues/395
FROM --platform=linux/amd64 rust:1.49.0-buster as fetch

ARG FLEXO_VERSION

WORKDIR /tmp

RUN mkdir /tmp/flexo_sources

RUN wget -q https://github.com/nroi/flexo/archive/$FLEXO_VERSION.tar.gz -O flexo.tar.gz && \
    wget -q https://github.com/nroi/scruffy/archive/0.1.0.tar.gz -O scruffy.tar.gz && \
    tar xf flexo.tar.gz && \
    tar xf scruffy.tar.gz

RUN cd /tmp/flexo-$FLEXO_VERSION/flexo && \
    cargo vendor && \
    cd .. && \
    cp -r flexo /tmp/flexo_sources/ && \
    cp /tmp/flexo-$FLEXO_VERSION/flexo_purge_cache /tmp/flexo_purge_cache

RUN cd '/tmp/scruffy-0.1.0' && \
    cargo vendor && \
    cd .. && \
    cp -r 'scruffy-0.1.0' /tmp/scruffy_sources

FROM rust:1.49.0-buster as build

COPY --from=fetch /tmp/flexo_sources/ /tmp/flexo_sources
COPY --from=fetch /tmp/scruffy_sources/ /tmp/scruffy_sources
COPY --from=fetch /tmp/flexo_purge_cache /tmp/flexo_purge_cache

RUN mkdir /tmp/flexo_sources/flexo/.cargo && \
    mkdir /tmp/scruffy_sources/.cargo

COPY cargo-config /tmp/flexo_sources/flexo/.cargo/config
COPY cargo-config /tmp/scruffy_sources/.cargo/config

RUN cd /tmp/flexo_sources/flexo && \
    cargo build --release --offline && \
    cp target/release/flexo /tmp/flexo

RUN cd /tmp/scruffy_sources && \
    cargo build --release --offline && \
    cp target/release/scruffy /tmp/scruffy

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
    FLEXO_LISTEN_IP_ADDRESS="0.0.0.0" \
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
    FLEXO_MIRRORS_AUTO_TIMEOUT=350 \
    FLEXO_MIRRORLIST_LATENCY_TEST_RESULTS_FILE="/var/cache/flexo/state/latency_test_results.json" \
    FLEXO_NUM_VERSIONS_RETAIN=3

ENV RUST_LOG="info"

COPY --from=build /tmp/flexo /usr/bin/flexo
COPY --from=build /tmp/flexo_purge_cache /usr/bin/flexo_purge_cache
COPY --from=build /tmp/scruffy /usr/bin/scruffy

ENTRYPOINT /usr/bin/flexo
