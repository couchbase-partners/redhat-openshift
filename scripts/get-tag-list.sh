#!/bin/bash -e

# Reaches out to the RHCC REST API and returns a JSON object describing
# the available tags for the specified product (couchbase-server, etc).
# Result looks like this:
#
#  {"name":"couchbase/server","tags":["5.5.1-1","6.0.1-1","6.0.3-1", ...}
#
# Note that our "added" tags such as :6.5.0 and :latest WILL be included,
# in addition to the ones we initially pushed such as :6.5.0-1.

PRODUCT=$1
shift

# Some informational settings
CONF_DIR=/home/couchbase/openshift/${PRODUCT}
IMAGE_NAME=$(cat ${CONF_DIR}/image_name)

# Do OAuth dance with RHCC
tokenUri="https://registry.connect.redhat.com/auth/realms/rhc4tp/protocol/redhat-docker-v2/auth"
# This is a "Registry Service Account" on access.redhat.com associated with the rhel8-couchbase user
username='7638313|rhel8-couchbase'
set +x
password=$(cat /home/couchbase/openshift/rhcc/registry-service-token.txt)
# Obtain short-duration access token from auth server
data=("service=docker-registry" "client_id=curl" "scope=repository:rhel:pull")
token=$(curl --silent -L --user "$username:$password" --get --data-urlencode ${data[0]} --data-urlencode ${data[1]} --data-urlencode ${data[2]} $tokenUri |
        python -c 'import sys, json; print (json.load(sys.stdin)["token"])')

listUri="https://registry.connect.redhat.com/v2/$IMAGE_NAME/tags/list"
curl --silent -H "Accept: application/json" -H "Authorization: Bearer $token" --get -H "Accept: application/json" $listUri
