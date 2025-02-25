#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

REPO_PATH=$MY_PATH/../..

## | -------------------------- args -------------------------- |

# INPUTS
LIST=$1
VARIANT=$2
REPOSITORY=$3
BASE_IMAGE=$4
DOCKER_IMAGE=$5
ARTIFACTS_FOLDER=$6
PIPELINE_BUILD=$7 # {pipeline, onpush}

[ -z $RUN_LOCALLY ] && RUN_LOCALLY=false

# default for testing

[ -z $LIST ] && LIST=nonbloom
[ -z $VARIANT ] && VARIANT=unstable
[ -z $REPOSITORY ] && REPOSITORY=mrs_uav_shell_additions
[ -z $BASE_IMAGE ] && BASE_IMAGE=ctumrs/ros_noetic:2025-02-05
[ -z $DOCKER_IMAGE ] && DOCKER_IMAGE=noetic_builder
[ -z $ARTIFACTS_FOLDER ] && ARTIFACTS_FOLDER=/tmp/artifacts
[ -z $PIPELINE_BUILD ] && PIPELINE_BUILD="pipeline"

## | ---------------------- derived args ---------------------- |

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

YAML_FILE=$REPO_PATH/${LIST}.yaml

# needed for building open_vins
export ROS_VERSION=1

REPOS=$($REPO_PATH/scripts/helpers/get_repo_source.py $YAML_FILE $VARIANT $ARCH $REPOSITORY)

# clone and checkout
echo "$REPOS" | while IFS= read -r REPO; do

  cd /tmp

  sudo rm -rf repository

  REPO_NAME=$(echo "$REPO" | awk '{print $1}')
  URL=$(echo "$REPO" | awk '{print $2}')
  BRANCH=$(echo "$REPO" | awk '{print $3}')
  GITMAN=$(echo "$REPO" | awk '{print $4}')

  echo "$0: cloning '$URL --depth 1 --branch $BRANCH' into '$REPO'"
  [ -e repository ] && rm -rf repository || git clone $URL --recurse-submodules --shallow-submodules --depth 1 --branch $BRANCH repository

  if [[ "$GITMAN" == "True" ]]; then
    cd repository
    pipx install gitman
    [[ -e .gitman.yml || -e .gitman.yaml ]] && gitman install
  fi

done

echo "$0: repository cloned to /tmp/repository"

## | --------------------- prepare docker --------------------- |

$REPO_PATH/ci_scripts/helpers/wait_for_docker.sh

if ! $RUN_LOCALLY; then

  echo "$0: logging in to docker registry"

  echo $PUSH_TOKEN | docker login ghcr.io -u ctumrsbot --password-stdin

fi

TRANSPORT_IMAGE=alpine:latest

docker buildx use default

echo "$0: loading cached builder docker image"


if ! $RUN_LOCALLY; then

  docker pull ghcr.io/ctu-mrs/buildfarm:$DOCKER_IMAGE
  docker tag ghcr.io/ctu-mrs/buildfarm:$DOCKER_IMAGE $DOCKER_IMAGE

fi

echo "$0: image loaded"

mkdir -p /tmp/debs
mkdir -p /tmp/other_files

cp $MY_PATH/entrypoint.sh /tmp/other_files/entrypoint.sh

## | ---------------------- run the build --------------------- |

docker run \
  --rm \
  -v /tmp/repository:/etc/docker/repository \
  -v /tmp/debs:/etc/docker/debs \
  -v /tmp/other_files:/etc/docker/other_files \
  $DOCKER_IMAGE \
  /bin/bash -c "/etc/docker/other_files/entrypoint.sh $VARIANT /etc/docker/debs $BASE_IMAGE $PIPELINE_BUILD"

# if there are any artifacts, update the builder image

DEBS_EXIST=$(ls /tmp/debs | grep ".deb" | wc -l)

if [ $DEBS_EXIST -gt 0 ]; then

  echo "$0: copying artifacts"

  cp -r /tmp/debs/* $ARTIFACTS_FOLDER/

fi

echo "$0: "
echo "$0: artifacts are:"

ls $ARTIFACTS_FOLDER
