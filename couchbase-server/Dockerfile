# Dockerfile to build the OpenShift image for couchbase-server

# Stage 0: compile runit. We use the "python" base as it includes
# most C-language build tools as well.
FROM registry.access.redhat.com/ubi8/python-36 as runit_build

ARG RUNIT_VER=2.1.2
USER root
RUN dnf install -y glibc-static && dnf clean all
RUN set -x \
    && mkdir /tmp/runit \
    && cd /tmp/runit \
    && curl -O http://smarden.org/runit/runit-${RUNIT_VER}.tar.gz \
    && tar xf runit-${RUNIT_VER}.tar.gz \
    && cd admin/runit-${RUNIT_VER} \
    && package/install

# Stage 1: build Couchbase Server image.

FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG RUNIT_VER=2.1.2
LABEL maintainer="build-team@couchbase.com"

# ubi-minimal updates frequently and has very few packages installed,
# so no need for a "security-only" update.
RUN microdnf update && microdnf clean all

# Install yum dependencies
RUN microdnf -y install \
        findutils \
        gzip \
        hostname \
        lsof \
        lshw \
        net-tools \
        procps-ng \
        psmisc \
        tar \
        unzip \
        zip \
    && microdnf clean all

# Copy runit from stage 0
COPY --from=runit_build /tmp/runit/admin/runit-${RUNIT_VER}/command/* /sbin/

# Add licenses and help file
COPY licenses /licenses
COPY help.1 /help.1

ARG PROD_VERSION
ARG STAGING
ARG CB_RELEASE_URL=http://packages${STAGING}.couchbase.com/releases/${PROD_VERSION}
ARG CB_PACKAGE=couchbase-server-enterprise-${PROD_VERSION}-rhel8.x86_64.rpm

ENV PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN set -x \
    && groupadd -g1000 couchbase \
    && useradd couchbase -g couchbase -u1000 -m -s /bin/bash  \
    && echo 'couchbase:couchbase' | chpasswd

# Install Couchbase Server, working around microdnf limitations to
# install dependencies
RUN set -x \
    && curl --fail -o /tmp/couchbase.rpm $CB_RELEASE_URL/$CB_PACKAGE \
    && microdnf install $(rpm -qpR /tmp/couchbase.rpm | egrep -v "^(config|rpmlib|libc.so|/bin/sh)") \
    && rpm -Uvh /tmp/couchbase.rpm \
    && rm /tmp/couchbase.rpm \
    && microdnf clean all
RUN chmod -R o+rwx /opt/couchbase/etc
RUN chmod -R o+rwx /opt/couchbase/var

# Update VARIANT.txt to indicate we're running in our Docker image
RUN sed -i -e '1 s/$/\/docker/' /opt/couchbase/VARIANT.txt

# Add runit script for couchbase-server
COPY scripts/run /service/couchbase-server/run
RUN chmod go+rwx /service/couchbase-server

# Temporary fix for entrypoint
#RUN chmod o+rx /sbin/*

# Add dummy script for commands invoked by cbcollect_info that
# make no sense in a Docker container
COPY scripts/dummy.sh /usr/local/bin/
RUN set -x \
    && ln -s dummy.sh /usr/local/bin/iptables-save \
    && ln -s dummy.sh /usr/local/bin/lvdisplay \
    && ln -s dummy.sh /usr/local/bin/vgdisplay \
    && ln -s dummy.sh /usr/local/bin/pvdisplay

LABEL name="couchbase/server" \
      vendor="Couchbase" \
      version="${PROD_VERSION}" \
      release="Latest" \
      summary="Couchbase Server ${PROD_VERSION} Enterprise" \
      description="Couchbase Server ${PROD_VERSION} Enterprise" \
      architecture="x86_64" \
      run="docker run -d --privileged -p 8091:8091 --restart always \
           --name NAME IMAGE" \
      io.k8s.description="Couchbase Server is the world's most complete, scalable, and highest performing NoSQL database. We engineered the product to meet the most demanding enterprise and big data requirements for distributed database performance and scalability." \
      io.openshift.expose-services="8091/tcp:rest,18091/tcp:ssl_rest,8092/tcp:capi,18092/tcp:ssl_capi,8093/tcp:query,18093/tcp:ssl_query,8094/tcp:fts_http,18094/tcp:fts_ssl,8095/tcp:cbas_http,18095/tcp:cbas_ssl,8096/tcp:eventing_http,18096/tcp:eventing_ssl,8097/tcp:backup_http,18097/tcp:backup_ssl,9123/tcp:prometheus_http,11210/tcp:memcached,11207/tcp:memcached_ssl,11280/tcp:memcached_prometheus"

COPY scripts/entrypoint.sh /

USER 1000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["couchbase-server"]

EXPOSE 8091 \
       8092 \
       8093 \
       8094 \
       8095 \
       8096 \
       8097 \
       9123 \
       11207 \
       11210 \
       11280 \
       18091 \
       18092 \
       18093 \
       18094 \
       18095 \
       18096 \
       18097

VOLUME /opt/couchbase/var
