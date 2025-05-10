FROM golang:1.24-alpine AS etcd-builder

LABEL maintainer="Sonic <sonic@djls.io>"
LABEL org.opencontainers.image.source=https://github.com/justereseau/omni_etcd_backup
LABEL org.opencontainers.image.description="This is a simple image that contain the requirement to backup an etcd omni instance to B2."
LABEL org.opencontainers.image.licenses=WTFPL

ARG ETCD_VERSION=latest

RUN apk add --no-cache bash curl jq git

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

# =============================================

FROM python:3.13-alpine AS b2-builder

ARG B2_VERSION=latest

RUN apk add --no-cache curl git jq patchelf && pip install -U pdm

RUN mkdir /build
WORKDIR /build

# Get the B2's source code
RUN export PDM_BUILD_SCM_VERSION=$(curl -s https://api.github.com/repos/Backblaze/B2_Command_Line_Tool/releases/${B2_VERSION} | jq -r '.tag_name') && \
  curl -sL https://github.com/Backblaze/B2_Command_Line_Tool/archive/refs/tags/$PDM_BUILD_SCM_VERSION.tar.gz -o /tmp/b2-source.tar.gz && \
  tar -xzf /tmp/b2-source.tar.gz --strip-components=1 && \
  pdm install --prod --group license && \
  pdm run b2 license --dump --with-packages && \
  rm -r .venv && mkdir __pypackages__ && pdm install --prod --group full --no-editable && \
  mv /build/__pypackages__/$(python -V | awk '{print $2}' | cut -d '.' -f 1-2)/* /build/__pypackages__ && \
  rm -r /build/__pypackages__/$(python -V | awk '{print $2}' | cut -d '.' -f 1-2)

# =============================================

FROM python:3.13-alpine

# Copy required binaries from etcd image
COPY --from=etcd-builder /build/bin/etcdctl /usr/local/bin/etcdctl
COPY --from=etcd-builder /build/bin/etcdutl /usr/local/bin/etcdutl

# Copy required binaries from b2 image
COPY --from=b2-builder /build/__pypackages__/bin/b2 /usr/local/bin/b2
COPY --from=b2-builder /build/__pypackages__/lib /opt/b2

# Configuring the environment for b2
ENV B2_CLI_DOCKER=1
ENV PYTHONPATH=/build/__pypackages__/lib

# Ensure the binaries version
RUN echo "   etcd version: $(etcd --version)" >> /tmp/build-out.txt && \
  echo "etcdctl version: $(etcdctl version)" >> /tmp/build-out.txt && \
  echo "etcdutl version: $(etcdutl version)" >> /tmp/build-out.txt && \
  echo "     b2 version: $(b2 version)" >> /tmp/build-out.txt && \
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
