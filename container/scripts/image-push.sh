#!/bin/bash

#docker ps
#docker image ls
set -e

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "369463259913.dkr.ecr.$REGION.amazonaws.com"

docker image push "$REPOSITORY_URL:latest"
