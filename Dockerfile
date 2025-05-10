FROM alpine:3.21.3
LABEL maintainer="Sonic <sonic@djls.io>"
LABEL org.opencontainers.image.source=https://github.com/justereseau/omni_etcd_backup
LABEL org.opencontainers.image.description="This is a simple image that contain the requirement to backup an etcd omni instance to B2."
LABEL org.opencontainers.image.licenses=WTFPL

RUN apk add --no-cache wget

COPY build.sh /opt/build.sh
RUN chmod +x /opt/build.sh
RUN /opt/build.sh

# ENTRYPOINT [ "/opt/build.sh" ]

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
