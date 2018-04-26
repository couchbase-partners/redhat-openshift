#!/bin/bash -e

# Basic help information
function show_help {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -p : Product to build and upload from (e.g. couchbase-server) (Required)"
    echo "  -v : Version of product to use (e.g. 5.1.0) (Required)"
    echo "  -b : Build number of image (Optional, defaults to 1)"
    echo "  -t : Build testing image and tarball (Boolean)"
    exit 0
}

# Parse options and ensure required ones are there
while getopts :p:v:b:th opt; do
    case ${opt} in
        p) PRODUCT="$OPTARG"
           ;;
        v) VERSION="$OPTARG"
           ;;
        b) BUILD="$OPTARG"
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

# Check for testing build and set up variables accordingly
DOCKER_FILE=Dockerfile
NAME_EXT=""

if [[ "$TESTING" == "true" ]]; then
   NAME_EXT="-testing"

   if [[ -e "Dockerfile.testing" ]]; then
       DOCKER_FILE=Dockerfile.testing
   fi
fi

# Enter product directory
cd ${PRODUCT}

# Some informational settings
CONF_DIR=/root/openshift/${PRODUCT}
IMAGE=${PRODUCT}-${VERSION}-openshift${NAME_EXT}
PROJECT_ID=$(cat ${CONF_DIR}/project_id)
UPLOAD_HOST=scan.connect.redhat.com
UPLOAD_URI=${UPLOAD_HOST}/${PROJECT_ID}/${IMAGE}:${VERSION}-${BUILD}

# Build image, acquiring image ID (needed for upload)
IMAGE_ID=$(docker build -q --build-arg PROD_VERSION=${VERSION} -f ${DOCKER_FILE} -t ${IMAGE} . 2>/dev/null | awk '/Successfully built/{print $NF}')

# If testing, create tarball of image, else tag and upload image to OpenShift
if [[ "$TESTING" == "true" ]]; then
    docker save -o ${IMAGE}.tar ${IMAGE}
else
    docker login -u unused -p "$(cat ${CONF_DIR}/registry_key)" -e none ${UPLOAD_HOST}
    docker tag ${IMAGE_ID} ${UPLOAD_URI}
    docker push ${UPLOAD_URI}
fi
