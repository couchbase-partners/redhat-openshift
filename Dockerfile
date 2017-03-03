#FROM centos:6
# This is a RHEL 7 image from Redhat
FROM registry.access.redhat.com/rhel7

MAINTAINER Couchbase Docker Team <docker@couchbase.com>


# Install yum dependencies
RUN yum install -y tar \
    && yum clean all && \
      yum -y install openssl \
      lsof lshw net-tools numactl \
      sysstati wget screen psmisc zip unzip \
      gzip

RUN curl https://bootstrap.pypa.io/get-pip.py | python - ; pip install httplib2

COPY functions /etc/init.d/

# Install gosu for startup script
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -sSL "https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd

ENV CB_VERSION=4.6.0 \
    CB_RELEASE_URL=http://packages.couchbase.com/releases \
    CB_PACKAGE=couchbase-server-enterprise-4.6.0-centos7.x86_64.rpm \
    PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Install couchbase
RUN rpm --install $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE

#clean the cache
RUN yum clean all


COPY scripts/couchbase-start /usr/local/bin/

LABEL Name=rhel7/couchbase-server
LABEL Release=Latest 
LABEL Vendor=Couchbase 
LABEL Version=4.6.0 
LABEL Architecture="x86_64"
LABEL RUN="docker run -d --rm --privileged -p 8091:8091 --restart always --name NAME IMAGE \
            -v /opt/couchbase/var:/opt/couchbase/var \
            -v /opt/couchbase/var/lib/moxi:/opt/couchbase/var/lib/moxi \
            -v /opt/couchbase/var/lib/stats:/opt/couchbase/var/lib/stats "


ENTRYPOINT ["couchbase-start"]
CMD ["couchbase-server", "--", "-noinput"]
# pass -noinput so it doesn't drop us in the erlang shell

EXPOSE 8091 8092 8093 11207 11210 11211 18091 18092
#VOLUME /opt/couchbase/var
