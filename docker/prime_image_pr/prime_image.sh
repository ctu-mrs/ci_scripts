#!/bin/bash

#
# ./prime_image.sh <base image> <output image> <variant> <artifacts folder>
#

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

REPO_PATH=$MY_PATH/../..
source $REPO_PATH/helpers/retry.sh

cd $MY_PATH

## | ------------------------ arguments ----------------------- |

BASE_IMAGE=$1
OUTPUT_IMAGE=$2
PPA_VARIANT=$3
ARTIFACTS_FOLDER=$4
REPOSITORY_NAME=$5

echo "$0: BASE_IMAGE=$BASE_IMAGE"
echo "$0: OUTPUT_IMAGE=$OUTPUT_IMAGE"
echo "$0: PPA_VARIANT=$PPA_VARIANT"
echo "$0: ARTIFACTS_FOLDER=$ARTIFACTS_FOLDER"
echo "$0: REPOSITORY_NAME=$REPOSITORY_NAME"

[ -z $RUN_LOCALLY ] && RUN_LOCALLY=false

# defaults for testing

[ -z $BASE_IMAGE ] && BASE_IMAGE=ctumrs/ros_jazzy:latest
[ -z $OUTPUT_IMAGE ] && OUTPUT_IMAGE=jazzy_builder
[ -z $PPA_VARIANT ] && PPA_VARIANT=unstable
[ -z $ARTIFACTS_FOLDER ] && ARTIFACTS_FOLDER=/tmp/artifacts
[ -z $REPOSITORY_NAME ] && REPOSITORY_NAME=buildfarm2

## | ---------------------- docker build ---------------------- |

echo "$0: pulling the base image"

$REPO_PATH/helpers/wait_for_docker.sh

retry 4 docker pull $BASE_IMAGE

docker buildx use default

echo "$0: building the image"
cp $REPO_PATH/helpers/add_private_ppa.sh ./
trap 'rm -f add_private_ppa.sh' EXIT

PRIVATE_PPA_SECRET_ARG=()
if [[ -n ${PRIVATE_PPA_TOKEN:-} ]]; then
  PRIVATE_PPA_SECRET_ARG=(--secret id=PRIVATE_PPA_TOKEN,env=PRIVATE_PPA_TOKEN)
fi

docker build . --file Dockerfile \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg PPA_VARIANT=${PPA_VARIANT} \
  "${PRIVATE_PPA_SECRET_ARG[@]}" \
  --tag ${OUTPUT_IMAGE} --progress plain

mkdir -p $ARTIFACTS_FOLDER

IMAGE_SHA=$(docker inspect --format='{{index .Id}}' ${BASE_IMAGE} | head -c 15 | tail -c 8)

echo $IMAGE_SHA > $ARTIFACTS_FOLDER/base_sha.txt
