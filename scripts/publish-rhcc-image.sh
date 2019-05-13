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
IMAGE_NAME=$(cat ${CONF_DIR}/image_name)

# Need to login for production (Red Hat) registry
docker login -u unused -p "$(cat ${CONF_DIR}/registry_key)" ${UPLOAD_HOST}

# Compute full image names
INPUT_IMAGE=build-docker.couchbase.com/${IMAGE_NAME}:${VERSION}
BASE_VERSION=${VERSION/-*/}
OUTPUT_IMAGE=scan.connect.redhat.com/${PROJECT_ID}/unused:${BASE_VERSION}-${BUILD}

# Ensure image is available locally to be pushed
docker pull ${INPUT_IMAGE}

docker tag ${INPUT_IMAGE} ${OUTPUT_IMAGE}
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo Pushing ${INPUT_IMAGE}
echo as ${OUTPUT_IMAGE}
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

docker push ${OUTPUT_IMAGE}
docker rmi ${INPUT_IMAGE}
docker rmi ${OUTPUT_IMAGE}
