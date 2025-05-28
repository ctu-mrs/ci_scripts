#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

REPO_PATH=$MY_PATH/../..

## | -------------------------- args -------------------------- |

BASE_IMAGE=$1
REPOSITORY_NAME=$2
PPA_VARIANT=$3
PATH_TO_DOCKER_FOLDER=$4

[ -z $RUN_LOCALLY ] && RUN_LOCALLY=false

# default for testing
[ -z $BASE_IMAGE ] && BASE_IMAGE=ctumrs/ros_jazzy:latest
[ -z $REPOSITORY_NAME ] && REPOSITORY_NAME=realsense
[ -z $PPA_VARIANT ] && PPA_VARIANT=unstable
[ -z $PATH_TO_DOCKER_FOLDER ] && PATH_TO_DOCKER_FOLDER=~/git/realsense/docker

## | ---------------------- derived args ---------------------- |

OUTPUT_IMAGE=ctumrs/${REPOSITORY_NAME}:unstable

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

$REPO_PATH/helpers/wait_for_docker.sh

docker buildx use default

if ! $RUN_LOCALLY; then

  echo "$0: logging in to docker registry"

  docker login --username klaxalk --password $TOKEN

fi

echo "$0: building the image"

cd $PATH_TO_DOCKER_FOLDER

docker build . --file Dockerfile --build-arg BASE_IMAGE=${BASE_IMAGE} --build-arg PPA_VARIANT=${PPA_VARIANT} --tag ${OUTPUT_IMAGE} --progress plain --no-cache

echo "$0: exporting image"

if ! $RUN_LOCALLY; then

  docker push ${OUTPUT_IMAGE}

fi
