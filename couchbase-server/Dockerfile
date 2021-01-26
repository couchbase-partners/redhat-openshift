# Dockerfile to build the OpenShift image for couchbase-server

# This is a RHEL 7 image from Redhat
FROM registry.access.redhat.com/rhel7

LABEL maintainer="build-team@couchbase.com"

RUN yum repolist --disablerepo="*" && \
    yum-config-manager --enable rhel-7-server-rpms rhel-7-server-rt-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms \
        rhel-7-server-extras-rpms rhel-server-rhscl-7-rpms && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
        --setopt=tsflags=nodocs && \
    yum clean all

# Install yum dependencies
RUN yum -y install tar \
      lsof lshw net-tools \
      psmisc zip unzip \
      gzip \
    && yum clean all

# Install sshd only if TESTING
ARG TESTING
RUN if [ "x$TESTING" = "xtrue" ]; then \
        yum install -y openssh openssh-server; \
        yum clean all; \
    fi

# Install runit
RUN curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.rpm.sh | bash \
    && yum -y install runit \
    && yum clean all

COPY functions /etc/init.d/

# Add licenses and help file
COPY licenses /licenses
COPY help.1 /help.1

ARG PROD_VERSION
ARG STAGING
ARG CB_RELEASE_URL=http://packages${STAGING}.couchbase.com/releases/${PROD_VERSION}
ARG CB_PACKAGE=couchbase-server-enterprise-${PROD_VERSION}-centos7.x86_64.rpm

ENV PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd

# Install couchbase
RUN yum install -y $CB_RELEASE_URL/$CB_PACKAGE \
    && yum clean all
RUN chmod -R o+rwx /opt/couchbase/etc
RUN chmod -R o+rwx /opt/couchbase/var

# Update VARIANT.txt to indicate we're running in our Docker image
RUN sed -i -e '1 s/$/\/docker/' /opt/couchbase/VARIANT.txt

# Add runit script for couchbase-server
COPY scripts/run /etc/service/couchbase-server/run
RUN chmod go+rwx /etc/service/couchbase-server

# Temporary fix for entrypoint
RUN chmod o+rx /sbin/*

# Add dummy script for commands invoked by cbcollect_info that
# make no sense in a Docker container
COPY scripts/dummy.sh /usr/local/bin/
RUN ln -s dummy.sh /usr/local/bin/iptables-save && \
    ln -s dummy.sh /usr/local/bin/lvdisplay && \
    ln -s dummy.sh /usr/local/bin/vgdisplay && \
    ln -s dummy.sh /usr/local/bin/pvdisplay

# Clean the cache
RUN yum clean all

LABEL name="couchbase/server" \
      vendor="Couchbase" \
      version="${PROD_VERSION}" \
      release="Latest" \
      summary="Couchbase Server ${PROD_VERSION} Enterprise" \
      description="Couchbase Server ${PROD_VERSION} Enterprise" \
      architecture="x86_64" \
      run="docker run -d --privileged -p 8091:8091 --restart always \
           --name NAME IMAGE"

COPY scripts/entrypoint.sh /

USER 1000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["couchbase-server"]

EXPOSE 8091 8092 8093 8094 11207 11210 11211 18091 18092 18093
VOLUME /opt/couchbase/var
