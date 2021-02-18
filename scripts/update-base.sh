#!/bin/bash -ex

DOCKERFILE=$1

base=$(grep FROM ${DOCKERFILE} | grep -v " as " | cut -d' ' -f2)

if [ "${base}" = "scratch" ]; then
    echo "Not updating 'scratch' base image"
else
    echo "Updating base image ${base}"
    docker pull ${base}
fi
