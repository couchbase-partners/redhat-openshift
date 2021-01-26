#!/bin/bash
set -e

type sshd >& /dev/null && /usr/sbin/sshd -D &

[[ "$1" == "couchbase-server" ]] && {
    echo "Starting Couchbase Server -- Web UI available at http://<ip>:8091 and logs available in /opt/couchbase/var/lib/couchbase/logs"
    exec /sbin/runsvdir-start
}

exec "$@"
