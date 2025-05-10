FROM golang:1.24-alpine AS etcd-builder

LABEL maintainer="Sonic <sonic@djls.io>"
LABEL org.opencontainers.image.source=https://github.com/justereseau/omni_etcd_backup
LABEL org.opencontainers.image.description="This is a simple image that contain the requirement to backup an etcd omni instance to B2."
LABEL org.opencontainers.image.licenses=WTFPL

ARG ETCD_VERSION=latest

RUN apk add --no-cache bash curl jq git

RUN mkdir /build
WORKDIR /build

# Get the source code
RUN RELEASE_NAME=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/${ETCD_VERSION} | jq -r '.tag_name') && \
  curl -sL https://github.com/etcd-io/etcd/archive/refs/tags/$RELEASE_NAME.tar.gz -o /tmp/source.tar.gz && \
  tar -xzf /tmp/source.tar.gz --strip-components=1

# Build the binaries
RUN case $(uname -m) in \
  x86_64) export GOOS=linux GOARCH=amd64 ;; \
  aarch64) export GOOS=linux GOARCH=arm64 ;; \
  armv7l) export GOOS=linux GOARCH=arm GOARM=7 ;; \
  *) echo "Unsupported architecture: $(uname -m)" ; exit 1 ;; \
  esac && \
  echo "Building for $GOOS/$GOARCH" > /tmp/build-out.txt && \
  ./build.sh

# =============================================

FROM golang:1.24-alpine AS mc-builder

ARG MC_VERSION=latest

RUN apk add --no-cache bash curl jq

RUN mkdir /build
WORKDIR /build

ENV GOPATH=/go
ENV CGO_ENABLED=0

RUN apk add -U --no-cache ca-certificates
RUN apk add -U curl
RUN curl -s -q https://raw.githubusercontent.com/minio/mc/master/LICENSE -o /go/LICENSE
RUN curl -s -q https://raw.githubusercontent.com/minio/mc/master/CREDITS -o /go/CREDITS

# Build the binaries
RUN case $(uname -m) in \
  x86_64) export GOOS=linux GOARCH=amd64 ;; \
  aarch64) export GOOS=linux GOARCH=arm64 ;; \
  armv7l) export GOOS=linux GOARCH=arm GOARM=7 ;; \
  *) echo "Unsupported architecture: $(uname -m)" ; exit 1 ;; \
  esac && \
  echo "Building for $GOOS/$GOARCH" > /tmp/build-out.txt && \
  go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)" "github.com/minio/mc@latest"


# # Get the source code
# RUN RELEASE_NAME=$(curl -s https://api.github.com/repos/minio/mc/releases/${MC_VERSION} | jq -r '.tag_name') && \
#   curl -sL https://github.com/minio/mc/archive/refs/tags/$RELEASE_NAME.tar.gz -o /tmp/source.tar.gz && \
#   tar -xzf /tmp/source.tar.gz --strip-components=1



# # =============================================

# FROM python:3.13-alpine

# # Install required packages
# RUN apk add --no-cache bash gnupg xz

# # Copy required binaries from etcd image
# COPY --from=etcd-builder /build/bin/etcdctl /usr/local/bin/etcdctl
# COPY --from=etcd-builder /build/bin/etcdutl /usr/local/bin/etcdutl

# # Copy required binaries from b2 image
# COPY --from=b2-builder /build/__pypackages__/bin/b2 /usr/local/bin/b2
# COPY --from=b2-builder /build/__pypackages__/lib /opt/b2

# # Configuring the environment for b2
# ENV B2_CLI_DOCKER=1
# ENV PYTHONPATH=/opt/b2

# # Ensure the binaries version
# RUN echo "   etcd version: $(etcd --version)" >> /tmp/build-out.txt && \
#   echo "etcdctl version: $(etcdctl version)" >> /tmp/build-out.txt && \
#   echo "etcdutl version: $(etcdutl version)" >> /tmp/build-out.txt && \
#   echo "     b2 version: $(b2 version)" >> /tmp/build-out.txt && \
#   cat /tmp/build-out.txt

# RUN mkdir /scripts

# COPY --chmod=0755 --chown=root:root backup.sh /scripts/backup.sh
# COPY --chmod=0755 --chown=root:root restore.sh /scripts/restore.sh

# ENTRYPOINT [ "/scripts/backup.sh" ]
