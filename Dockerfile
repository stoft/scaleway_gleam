ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.13.0
ARG LITESTREAM_VERSION=0.5.2

# Gleam stage
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Build stage
FROM erlang:${ERLANG_VERSION}-alpine AS build
COPY --from=gleam /bin/gleam /bin/gleam
COPY . /app/
RUN apk add --no-cache build-base
RUN cd /app && gleam export erlang-shipment

# Final stage
FROM erlang:${ERLANG_VERSION}-alpine
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
# RUN \
#     addgroup --system webapp &&
#     adduser --system webapp -g webapp
COPY --from=build /app/build/erlang-shipment /app
COPY healthcheck.sh /app/healthcheck.sh
COPY litestream.yml /app/litestream.yml
COPY entrypoint.sh /app/entrypoint.sh
RUN apk add --no-cache wget curl \
    && chmod +x /app/healthcheck.sh \
    && chmod +x /app/entrypoint.sh \
    # Install Litestream matching the container architecture
    && arch=$(uname -m) \
    && case "$arch" in \
         x86_64) litestream_arch=amd64 ;; \
         aarch64|arm64) litestream_arch=arm64 ;; \
         armv7l) litestream_arch=armv7 ;; \
         armv6l) litestream_arch=armv6 ;; \
         *) echo "Unsupported arch: $arch" && exit 1 ;; \
       esac \
    && wget -O /tmp/litestream.tar.gz \
         https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-${LITESTREAM_VERSION}-linux-${litestream_arch}.tar.gz \
    && tar -xzf /tmp/litestream.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/litestream \
    && rm /tmp/litestream.tar.gz
WORKDIR /app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /app/healthcheck.sh || exit 1
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
