# Dockerfile to build the OpenShift image for sync-gateway
FROM registry.access.redhat.com/ubi8/ubi-minimal

LABEL maintainer="build-team@couchbase.com"

# ubi-minimal updates frequently and has very few packages installed,
# so no need for a "security-only" update.
RUN set -x \
    && microdnf update \
    && microdnf install shadow-utils \
    && microdnf clean all

# Add licenses and help file
COPY licenses /licenses
COPY help.1 /help.1

ARG PROD_VERSION=2.5.1
ARG STAGING
ARG SG_RELEASE_URL=http://packages${STAGING}.couchbase.com/releases/couchbase-sync-gateway/${PROD_VERSION}
ARG SG_PACKAGE=couchbase-sync-gateway-enterprise_${PROD_VERSION}_x86_64.rpm

ENV PATH $PATH:/opt/couchbase-sync-gateway/bin

# Install Sync Gateway, working around microdnf limitations to
# install dependencies
RUN set -x \
    && curl --fail -o /tmp/sgw.rpm $SG_RELEASE_URL/$SG_PACKAGE \
    && microdnf install $(rpm -qpR /tmp/sgw.rpm | egrep -v "(config|rpmlib|rtld)" | sed -e 's/(.*//') \
    && rpm -Uvh /tmp/sgw.rpm \
    && rm /tmp/sgw.rpm \
    && microdnf clean all

LABEL name="couchbase/sync-gateway" \
      vendor="Couchbase" \
      version="${PROD_VERSION}" \
      release="Latest" \
      summary="Couchbase Sync Gateway ${PROD_VERSION} Enterprise" \
      description="Couchbase Sync Gateway ${PROD_VERSION} Enterprise" \
      architecture="x86_64" \
      run="docker run -p 4984:4984 -d IMAGE" \
      io.k8s.description="Sync Gateway maintains up-to-date copies of documents where users need them. On mobile devices for instant access and on servers in data centers for reasons such as synchronizing documents, sharing documents, and loss-protection. Mobile apps create, update, and delete files locally, Sync Gateway takes care of the rest."

# Create directory where the default config stores memory snapshots to disk
RUN mkdir /opt/couchbase-sync-gateway/data

# copy the default config into the container
COPY config/sync_gateway_config.json /etc/sync_gateway/config.json

# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

USER sync_gateway

# Expose ports
#  port 4984: public port, port 4985: admin port
EXPOSE 4984 4985
