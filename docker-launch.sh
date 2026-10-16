#!/usr/bin/env bash

# The image runs as the unprivileged `node` user, so ~/.aws is mounted into that
# user's home rather than root's. On Linux the host ~/.aws must be readable and
# writable by uid 1000 for the credential refresh to succeed.
docker run --rm -it -v ~/.aws:/home/node/.aws glima-devops/aws-azure-sso "$@"
