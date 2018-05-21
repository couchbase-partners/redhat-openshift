# This is a RHEL 7 image from Redhat
FROM registry.access.redhat.com/rhel7

MAINTAINER Couchbase Docker Team <docker@couchbase.com>


RUN yum-config-manager --enable rhel-7-server-optional-rpms \
        rhel-7-server-extras-rpms rhel-server-rhscl-7-rpms && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
        --setopt=tsflags=nodocs

# Install yum dependencies
RUN yum -y update && \
    yum install -y wget && \
    yum clean all

# Add licenses and help file
COPY licenses /licenses
COPY help.1 /help.1

ARG PROD_VERSION
ARG SG_RELEASE_URL=http://packages.couchbase.com/releases/couchbase-sync-gateway
ARG SG_PACKAGE=couchbase-sync-gateway-enterprise_${PROD_VERSION}_x86_64.rpm

ENV PATH $PATH:/opt/couchbase-sync-gateway/bin

# Install Sync Gateway
RUN wget $SG_RELEASE_URL/$PROD_VERSION/$SG_PACKAGE && \
    rpm -i $SG_PACKAGE && rm $SG_PACKAGE

# Clean the cache
RUN yum clean all

LABEL name="rhel7/sync-gateway"
LABEL vendor="Couchbase"
LABEL version="${PROD_VERSION}"
LABEL release="Latest"
LABEL summary="Couchbase Sync Gateway ${PROD_VERSION} Enterprise"
LABEL description="Couchbase Sync Gateway ${PROD_VERSION} Enterprise"
LABEL architecture="x86_64"
LABEL run="docker run -p 4984:4984 -d rhel7/sync-gateway"

# Create directory where the default config stores memory snapshots to disk
RUN mkdir /opt/couchbase-sync-gateway/data

# copy the default config into the container
COPY config/sync_gateway_config.json /etc/sync_gateway/config.json

# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

# Expose ports
#  port 4984: public port
EXPOSE 4984
