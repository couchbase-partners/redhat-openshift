# Dockerfile to build the OpenShift image for couchbase-server

# This is a RHEL 7 image from Redhat
FROM registry.access.redhat.com/rhel7

MAINTAINER Couchbase Docker Team <docker@couchbase.com>

RUN yum repolist --disablerepo="*" && \
    yum-config-manager --enable rhel-7-server-rpms rhel-7-server-rt-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms \
        rhel-7-server-extras-rpms rhel-server-rhscl-7-rpms && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
        --setopt=tsflags=nodocs

# Install yum dependencies
RUN yum -y install tar \
    && yum clean all && \
      yum -y install openssl \
      lsof lshw net-tools numactl python-httplib2 \
      sysstati wget screen psmisc zip unzip \
      gzip

# Install runit
RUN curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.rpm.sh | bash
RUN yum -y install runit

COPY functions /etc/init.d/

# Add licenses and help file
COPY licenses /licenses
COPY help.1 /help.1

ARG PROD_VERSION
ARG OS_BUILD
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
RUN rpm --install $CB_RELEASE_URL/$CB_PACKAGE
RUN chmod -R o+rwx /opt/couchbase/etc
RUN chmod -R o+rwx /opt/couchbase/var

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
