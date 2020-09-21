#!/bin/bash -e

# Rebuilds *all* RHCC images (currently only couchbase/server and
# couchbase/sync-gateway) which have "simple" X.Y.Z versions.

script_dir=$(dirname $(readlink -e -- "${BASH_SOURCE}"))

PYSCRIPT=$(cat <<EOF
import re
import sys
import json

regex = re.compile('^\d+\.\d+\.\d+$')
tags = json.load(sys.stdin)["tags"]
print (' '.join([t for t in tags if regex.match(t)]))
EOF
)

for product in couchbase-server sync-gateway; do

    versions=$("${script_dir}/get-tag-list.sh" ${product} | python -c "$PYSCRIPT")

    for version in ${versions}; do
        # If need be we could add logic here to skip older versions, etc.
        echo "Triggering rebuild of ${product} ${version}"
        cat > ${product}-${version}-republish.properties <<EOF
PRODUCT=${product}
VERSION=${version}
EOF
    done
done
