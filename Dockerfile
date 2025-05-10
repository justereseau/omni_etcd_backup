FROM golang:1.24-alpine AS etcd-builder

LABEL maintainer="Sonic <sonic@djls.io>"
LABEL org.opencontainers.image.source=https://github.com/justereseau/omni_etcd_backup
LABEL org.opencontainers.image.description="This is a simple image that contain the requirement to backup an etcd omni instance to B2."
LABEL org.opencontainers.image.licenses=WTFPL

ARG ETCD_VERSION=latest

RUN apk add --no-cache bash curl jq

RUN mkdir /build
WORKDIR /build

# Get the ETCd's source code
RUN ETCD_RELEASE_NAME=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/${ETCD_VERSION} | jq -r '.tag_name') && \
  curl -sL https://github.com/etcd-io/etcd/archive/refs/tags/$ETCD_RELEASE_NAME.tar.gz -o /tmp/etcd-source.tar.gz && \
  tar -xzf /tmp/etcd-source.tar.gz --strip-components=1

# Build ETCd's binaries
RUN case $(uname -m) in \
  x86_64) export GOOS=linux GOARCH=amd64 ;; \
  aarch64) export GOOS=linux GOARCH=arm64 ;; \
  armv7l) export GOOS=linux GOARCH=arm GOARM=7 ;; \
  *) echo "Unsupported architecture: $(uname -m)" ; exit 1 ;; \
  esac && \
  echo "Building for $GOOS/$GOARCH" > /tmp/build-out.txt && \
  ./build.sh

# Ensure the binaries version
RUN echo "etcd version:  $(/build/bin/etcd --version)" >> /tmp/build-out.txt && \
  echo "etcdctl version: $(/build/bin/etcdctl version)" >> /tmp/build-out.txt && \
  echo "etcdutl version: $(/build/bin/etcdutl version)" >> /tmp/build-out.txt && \
  cat /tmp/build-out.txt

ENTRYPOINT [ "cat", "/tmp/build-out.txt" ]

# FROM alpine:3.21.3



# COPY build.sh /build/build.sh
# RUN chmod +x /build/build.sh
# RUN /build/build.sh

# ENTRYPOINT [ "/build/build.sh" ]

# RUN /opt/build.sh

# # Copy required binaries from etcd image
# COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl
# COPY --from=etcd /usr/local/bin/etcdutl /usr/local/bin/etcdutl
# COPY --from=builder /usr/local/bin/b2 /usr/local/bin/b2

# RUN apk add --no-cache bash gnupg xz

# RUN mkdir /scripts

# COPY backup.sh /scripts/backup.sh
# RUN chmod +x /scripts/backup.sh

# COPY restore.sh /scripts/restore.sh
# RUN chmod +x /scripts/restore.sh

# ENTRYPOINT [ "/scripts/backup.sh" ]
