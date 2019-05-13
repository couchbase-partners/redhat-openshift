#!/bin/bash -ex

# Basic help information
function show_help {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -p : Product to build (e.g. couchbase-server) (Required)"
    echo "  -v : Version of product to use (e.g. 5.1.0) (Required)"
    echo "  -t : Build test image incl. sshd (Optional, defaults to false)"
    echo "  -s : Build from staging repository (Optional, defaults to false)"
    exit 0
}

STAGING=""

# Parse options and ensure required ones are there
while getopts :p:v:b:tsh opt; do
    case ${opt} in
        p) PRODUCT="$OPTARG"
           ;;
        v) VERSION="$OPTARG"
           ;;
        b) BUILD="$OPTARG"
           ;;
        t) TESTING="true"
           ;;
        s) STAGING="-staging"
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
    echo "Version of product (-v) is required"
    exit 1
fi

if [[ -z "$BUILD" ]]; then
    BUILD=1
fi

# Enter product directory
cd ${PRODUCT}

# Select correct Dockerfile
DOCKER_FILE=Dockerfile
if [[ "x$TESTING" = "xtrue" && -e "Dockerfile.testing" ]]; then
   DOCKER_FILE=Dockerfile.testing
fi

# Ensure base image is up-to-date
BASE_IMAGE=$(grep '^FROM' ${DOCKER_FILE}|cut -d' ' -f2)
docker pull ${BASE_IMAGE}

# Some informational settings
CONF_DIR=/home/couchbase/openshift/${PRODUCT}
IMAGE_NAME=$(cat ${CONF_DIR}/image_name)

IMAGE=build-docker.couchbase.com/${IMAGE_NAME}:${VERSION}-${BUILD}

# Build image
docker build --no-cache \
  --build-arg PROD_VERSION=${VERSION} \
  --build-arg STAGING=${STAGING} \
  -f ${DOCKER_FILE} -t ${IMAGE} .

echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo Pushing ${IMAGE}
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
docker push ${IMAGE}
docker rmi ${IMAGE}