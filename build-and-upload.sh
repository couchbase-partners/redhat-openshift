#!/bin/bash -ex

# Basic help information
function show_help {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -p : Product to build and upload from (e.g. couchbase-server) (Required)"
    echo "  -v : Version of product to use (e.g. 5.1.0) (Required)"
    echo "  -b : Build number of image (Optional, defaults to 1)"
    echo "  -s : Build staging test image and tarball (Boolean)"
    echo "  -t : Build testing image and tarball (Boolean)"
    exit 0
}

# Parse options and ensure required ones are there
while getopts :p:v:b:sth opt; do
    case ${opt} in
        p) PRODUCT="$OPTARG"
           ;;
        v) VERSION="$OPTARG"
           ;;
        b) BUILD="$OPTARG"
           ;;
        s) STAGING="true"
           ;;
        t) TESTING="true"
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

# Check for testing build and set up variables accordingly
DOCKER_FILE=Dockerfile
NAME_EXT=""
S3_STAGING=""

if [[ "$STAGING" == "true" || "$TESTING" == "true" ]]; then
   NAME_EXT="-testing"

   if [[ -e "Dockerfile.testing" ]]; then
       DOCKER_FILE=Dockerfile.testing
   fi

   if [[ "$STAGING" == "true" ]]; then
       S3_STAGING="-staging"
   fi
fi

# Some informational settings
CONF_DIR=/home/couchbase/openshift/${PRODUCT}
IMAGE=${PRODUCT}-${VERSION}-openshift${NAME_EXT}
PROJECT_ID=$(cat ${CONF_DIR}/project_id)

# Staging/testing builds are sent to internal registry
if [[ "$STAGING" == "true" || "$TESTING" == "true" ]]; then
    UPLOAD_HOST=build-docker.couchbase.com
    UPLOAD_URI=${UPLOAD_HOST}/couchbase/${IMAGE}:${VERSION}-${BUILD}
else
    UPLOAD_HOST=scan.connect.redhat.com
    UPLOAD_URI=${UPLOAD_HOST}/${PROJECT_ID}/${IMAGE}:${VERSION}-${BUILD}
fi


# Build image, acquiring image ID (needed for upload)
IMAGE_ID=$(docker build --build-arg PROD_VERSION=${VERSION} --build-arg OS_BUILD=${BUILD} --build-arg STAGING=${S3_STAGING} -f ${DOCKER_FILE} -t ${IMAGE} . 2>/dev/null | awk '/Successfully built/{print $NF}')

# Need to login for production (RedHat) registry
if [[ ! ("$STAGING" == "true" || "$TESTING" == "true") ]]; then
    docker login -u unused -p "$(cat ${CONF_DIR}/registry_key)" -e none ${UPLOAD_HOST}
fi

docker tag ${IMAGE_ID} ${UPLOAD_URI}
docker push ${UPLOAD_URI}
