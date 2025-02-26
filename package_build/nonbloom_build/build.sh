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
BASE_IMAGE=$1
DOCKER_IMAGE=$2
ARTIFACTS_FOLDER=$3
REPOSITORY_FOLDER=$4
REPOSITORY_NAME=$5

[ -z $RUN_LOCALLY ] && RUN_LOCALLY=false

# default for testing

[ -z $BASE_IMAGE ] && BASE_IMAGE=ctumrs/ros_noetic:2025-02-05
[ -z $DOCKER_IMAGE ] && DOCKER_IMAGE=noetic_builder
[ -z $ARTIFACTS_FOLDER ] && ARTIFACTS_FOLDER=/tmp/artifacts
[ -z $REPOSITORY_FOLDER ] && REPOSITORY_FOLDER=/home/klaxalk/git/mrs_uav_shell_additions
[ -z $REPOSITORY_NAME ] && REPOSITORY_NAME=mrs_uav_shell_additions

## | ---------------------- derived args ---------------------- |

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# needed for building open_vins
export ROS_VERSION=1

echo "$0: repository cloned to /tmp/repository"

cd $REPOSITORY_FOLDER

echo "$0: updating git submodules"
git submodule update --init --recursive

if [[ -e .gitman.yml || -e .gitman.yaml ]] && [[ ! -e .gitman_ignore ]] ; then

  pipx install gitman
  gitman install

fi

sudo rm -rf /tmp/repository
cp -r $REPOSITORY_FOLDER /tmp/repository

## | --------------------- prepare docker --------------------- |

$REPO_PATH/helpers/wait_for_docker.sh

if ! $RUN_LOCALLY; then

  echo "$0: logging in to docker registry"

  echo $PUSH_TOKEN | docker login ghcr.io -u ctumrsbot --password-stdin

fi

TRANSPORT_IMAGE=alpine:latest

docker buildx use default

echo "$0: loading cached builder docker image"


if ! $RUN_LOCALLY; then

  docker pull ghcr.io/ctu-mrs/$REPOSITORY_NAME:$DOCKER_IMAGE
  docker tag ghcr.io/ctu-mrs/$REPOSITORY_NAME:$DOCKER_IMAGE $DOCKER_IMAGE

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
  /bin/bash -c "/etc/docker/other_files/entrypoint.sh $VARIANT /etc/docker/debs $BASE_IMAGE"

# if there are any artifacts, update the builder image

DEBS_EXIST=$(ls /tmp/debs | grep ".deb" | wc -l)

if [ $DEBS_EXIST -gt 0 ]; then

  echo "$0: copying artifacts"

  cp -r /tmp/debs/* $ARTIFACTS_FOLDER/

fi

echo "$0: "
echo "$0: artifacts are:"

ls $ARTIFACTS_FOLDER
