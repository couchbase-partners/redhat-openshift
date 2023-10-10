#!/bin/bash -ex

# Basic help information
function show_help {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -p : Product to build (e.g. couchbase-server) (Required)"
    echo "  -v : Version of product to use (e.g. 5.1.0) (Required)"
    echo "  -b : Build number to use (eg. 1234) (Required)"
    echo "  -s : Build from staging repository (Optional, defaults to false)"
    echo "  -q : Quick build (disables docker build --no-cache)"
    echo "  -l : Pull build from latestbuilds, rather than download from S3"
    echo "       (Only works with most recent Server/SGW versions)"
    echo "  -n : Dry run (don't push to docker registries)"
    exit 0
}


function version_lt() {
    [ "${1}" = "${2}" ] && return 1 || [  "${1}" = "$(printf "${1}\n${2}" | sort -V | head -n1)" ]
}

function multiarch() {
    case "${PRODUCT}" in
        couchbase-server)
            version_lt ${VERSION} 7.1.3 && return 1
            ;;
        sync-gateway)
            version_lt ${VERSION} 3.0.4 && return 1
            ;;
    esac
    return 0
}

SCRIPT_DIR=$(dirname $(readlink -e -- "${BASH_SOURCE}"))

STAGING=""
CACHE_ARG="--no-cache"
DRYRUN=""
FROM_LATESTBUILDS="false"

# Parse options and ensure required ones are there
while getopts :p:v:b:qlsnh opt; do
    case ${opt} in
        p) PRODUCT="$OPTARG"
           ;;
        v) VERSION="$OPTARG"
           ;;
        b) BLD_NUM="$OPTARG"
           ;;
        s) STAGING="-staging"
           ;;
        q) CACHE_ARG=""
           ;;
        l) FROM_LATESTBUILDS="true"
           ;;
        n) DRYRUN="yes"
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

if [[ -z "$BLD_NUM" ]]; then
    echo "Build number of product (-b) is required"
    exit 1
fi
if [[ ${PRODUCT} == "couchbase-server" && $BLD_NUM -lt 10 ]]; then
    echo "Please use complete internal build number, not ${BLD_NUM}"
    exit 1
fi

# Use new UBI-based Dockerfile for Server 7.x or later, or SGW 3.x or later
if [[ ${PRODUCT} == "couchbase-server" ]]; then
    if [[ ${VERSION} =~ ^6.* ]]; then
        echo "Using legacy Dockerfile.6.x"
        DOCKERFILE=Dockerfile.old
    else
        DOCKERFILE=Dockerfile
    fi
elif [[ ${PRODUCT} == "sync-gateway" ]]; then
    if multiarch; then
        echo "Using multiarch Dockerfile.multiarch"
        DOCKERFILE=Dockerfile.multiarch
    elif [[ ${VERSION} =~ ^2.* ]]; then
        echo "Using legacy Dockerfile.2.x"
        DOCKERFILE=Dockerfile.2.x
    else
        echo "Using legacy Dockerfile.x64"
        DOCKERFILE=Dockerfile.x64
    fi
fi

# Enter product directory
cd ${PRODUCT}

# Determine image name per project - these are always uploaded to GHCR,
# so the build server should have push access there
if [[ ${PRODUCT} == "couchbase-server" ]]; then
    INTERNAL_IMAGE_NAME=cb-rhcc/server
else
    INTERNAL_IMAGE_NAME=cb-rhcc/sync-gateway
fi

BUILD_ARGS="--build-arg PROD_VERSION=${VERSION} --build-arg STAGING=${STAGING}"

# Override download locations if building from latestbuilds
if ${FROM_LATESTBUILDS}; then
    BUILD_ARGS+=" --build-arg RELEASE_BASE_URL="
    BUILD_ARGS+="https://latestbuilds.service.couchbase.com/builds/latestbuilds"
    BUILD_ARGS+="/${PRODUCT}/${RELEASE}/${BLD_NUM}"
    BUILD_ARGS+=" --build-arg PROD_VERSION=${VERSION}-${BLD_NUM}"
fi

# Build and push images
for registry in ghcr.io build-docker.couchbase.com; do
    IMAGE=${registry}/${INTERNAL_IMAGE_NAME}:${VERSION}-${BLD_NUM}

    ${SCRIPT_DIR}/update-base.sh ${DOCKERFILE}
    if [ "${DRYRUN}" = "yes" ]; then
        IMAGE=${registry}/${INTERNAL_IMAGE_NAME}:${VERSION}-${BLD_NUM}
        # For dry run where buildx is present and we're doing a multiarch
        # build, we build each architecture's image individually so we
        # can load them into the local image store for testing
        if multiarch; then
            for arch in amd64 arm64; do
            echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            echo Building ${IMAGE}-${arch}
            echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                docker buildx build --platform linux/${arch} --load \
                ${CACHE_ARG} ${BUILD_ARGS} \
                -f ${DOCKERFILE} -t ${IMAGE}-${arch} .
            done
        else
            echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            echo Building ${IMAGE}
            echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            docker build ${CACHE_ARG} ${BUILD_ARGS} \
            -f ${DOCKERFILE} -t ${IMAGE} .
        fi
    else
        echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        echo Building and Pushing ${IMAGE}
        echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        if multiarch; then
            docker buildx build --platform linux/amd64,linux/arm64 --push \
            ${CACHE_ARG} ${BUILD_ARGS} \
            -f ${DOCKERFILE} -t ${IMAGE} .
        else
            docker build ${CACHE_ARG} ${BUILD_ARGS} \
            -f ${DOCKERFILE} -t ${IMAGE} .
            docker push ${IMAGE}
            docker rmi ${IMAGE}
        fi
    fi
done
