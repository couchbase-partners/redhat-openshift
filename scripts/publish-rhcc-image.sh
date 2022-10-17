#!/bin/bash -ex

# Basic help information
function show_help {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -p : Product to publish (e.g. couchbase-server) (Required; determines credentials to use)"
    echo "  -v : Full version to publish including internal build number (eg. 6.5.0-1334) (Required)"
    echo "  -b : RHCC build number of image (Optional, defaults to 1)"
    exit 0
}

# Parse options and ensure required ones are there
while getopts :p:v:b:h opt; do
    case ${opt} in
        p) PRODUCT="$OPTARG"
           ;;
        v) VERSION="$OPTARG"
           ;;
        b) BUILD="$OPTARG"
           ;;
        h) show_help
           ;;
        \?) # Unrecognized option, show help
            echo -e \\n"Invalid option: ${OPTARG}" 1>&2
            show_help
    esac
done

if [[ -z "$PRODUCT" ]]; then
    echo "Product name (-p) is required"
    exit 1
fi

if [[ -z "$VERSION" ]]; then
    echo "Full version (-v) is required"
    exit 1
fi

if [[ -z "$BUILD" ]]; then
    BUILD=1
fi

# Some informational settings
CONF_DIR=/home/couchbase/openshift/${PRODUCT}
PROJECT_ID=$(cat ${CONF_DIR}/project_id)
if [[ ${PRODUCT} == "couchbase-server" ]]; then
    INTERNAL_IMAGE_NAME=cb-rhcc/server
else
    INTERNAL_IMAGE_NAME=cb-rhcc/sync-gateway
fi
INTERNAL_IMAGE=build-docker.couchbase.com/${INTERNAL_IMAGE_NAME}:${VERSION}

# Need to login for production (Red Hat) registry
docker login -u unused -p "$(cat ${CONF_DIR}/registry_key)" scan.connect.redhat.com

# Compute full image names
BASE_VERSION=${VERSION%-*}
OUTPUT_IMAGE=scan.connect.redhat.com/${PROJECT_ID}/unused:${BASE_VERSION}-${BUILD}
fi

# Copy image from internal to external repo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo Copying ${INTERNAL_IMAGE_NAME}
echo to ${OUTPUT_IMAGE}
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
skopeo copy ${INTERNAL_IMAGE_NAME} ${OUTPUT_IMAGE}
