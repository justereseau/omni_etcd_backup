FROM gcr.io/etcd-development/etcd:v3.5.14 as etcd

FROM alpine as builder

RUN apk add --no-cache wget

RUN wget https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux -O /usr/local/bin/b2 && \
  chmod +x /usr/local/bin/b2

FROM alpine
LABEL maintainer="Sonic <sonic@djls.io>"
LABEL org.opencontainers.image.source=https://github.com/justereseau/omni_etcd_backup
LABEL org.opencontainers.image.description="This is a simple image that contain the requirement to backup an etcd omni instance to B2."
LABEL org.opencontainers.image.licenses=WTFPL

# Copy required binaries from etcd image
COPY --from=etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl
COPY --from=builder /usr/local/bin/b2 /usr/local/bin/b2

RUN apk add --no-cache bash gnupg xz

RUN mkdir /scripts

COPY backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

# COPY restore.sh /scripts/restore.sh
# RUN chmod +x /scripts/restore.sh

ENTRYPOINT [ "/scripts/backup.sh" ]
