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

[ -z $BASE_IMAGE ] && BASE_IMAGE=ctumrs/ros_jazzy:latest
[ -z $DOCKER_IMAGE ] && DOCKER_IMAGE=jazzy_builder
[ -z $ARTIFACTS_FOLDER ] && ARTIFACTS_FOLDER=/tmp/artifacts
[ -z $REPOSITORY_FOLDER ] && REPOSITORY_FOLDER=/home/klaxalk/ws/src/nlopt_ros
[ -z $REPOSITORY_NAME ] && REPOSITORY_NAME=nlopt_ros

## | ---------------------- derived args ---------------------- |

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

ROSDEP_FILE="generated_${LIST}_${ARCH}.yaml"

# needed for building open_vins
export ROS_VERSION=1

cd $REPOSITORY_FOLDER

echo "$0: updating git submodules"
git submodule update --init --recursive

if [[ -e .gitman.yml || -e .gitman.yaml ]] && [[ ! -e .gitman_ignore ]] ; then

  pipx install gitman==3.5.2 --pip-args regex==2024.9.11
  gitman install

fi

sudo rm -rf /tmp/repository
cp -r $REPOSITORY_FOLDER /tmp/repository

## --------------------------------------------------------------
## |                        docker build                        |
## --------------------------------------------------------------

$REPO_PATH/helpers/wait_for_docker.sh

if ! $RUN_LOCALLY; then

  echo "$0: logging in to docker registry"

  echo $PUSH_TOKEN | docker login ghcr.io -u ctumrsbot --password-stdin

fi

docker buildx use default

echo "$0: loading cached builder docker image"

if ! $RUN_LOCALLY; then

  docker pull ghcr.io/ctu-mrs/$REPOSITORY_NAME:$DOCKER_IMAGE
  docker tag ghcr.io/ctu-mrs/$REPOSITORY_NAME:$DOCKER_IMAGE $DOCKER_IMAGE

fi

echo "$0: image loaded"

mkdir -p /tmp/debs
mkdir -p /tmp/other_files

cp $ARTIFACTS_FOLDER/base_sha.txt /tmp/other_files/base_sha.txt
cp $MY_PATH/entrypoint.sh /tmp/other_files/entrypoint.sh

$REPO_PATH/helpers/get_package_build_order.py /tmp/repository > /tmp/other_files/build_order.txt

echo "$0:"
echo "$0: builder order:"
cat /tmp/other_files/build_order.txt
echo "$0: "

## | ---------------------- run the test ---------------------- |

docker run \
  --rm \
  -v /tmp/repository:/etc/docker/repository \
  -v /tmp/debs:/etc/docker/debs \
  -v /tmp/other_files:/etc/docker/other_files \
  $DOCKER_IMAGE \
  /bin/bash -c "/etc/docker/other_files/entrypoint.sh"

# if there are any artifacts, update the builder image

DEBS_EXIST=$(ls /tmp/debs | grep ".deb" | wc -l)

if [ $DEBS_EXIST -gt 0 ]; then

  echo "$0: copying artifacts"

  mv /tmp/debs/* $ARTIFACTS_FOLDER/

fi

echo "$0: "
echo "$0: artifacts are:"

ls $ARTIFACTS_FOLDER
