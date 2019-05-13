build-rhcc-image.sh is used with the Dockerfiles, etc. in this repository
to build an image suitable for the Red Hat Container Catalog.

publish-rhcc-image.sh uses credentials stored on the build slave to
upload these images (or other RHCC-ready images, such as those for
Couchbase Autonomous Operator) to the RHCC scan service, using credentials
stored on the build slaves.
