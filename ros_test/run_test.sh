#!/bin/bash

#
# ./run_tests.sh <repository path> <docker image>
#

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

REPO_PATH=${MY_PATH}/..

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

## | ------------------------ arguments----------------------- |

SOURCES_PATH=$1
DOCKER_IMAGE=$2
REPOSITORY_NAME=$3

[ -z $RUN_LOCALLY ] && RUN_LOCALLY=false

# defaults for testing

[ -z $DOCKER_IMAGE ] && DOCKER_IMAGE=jazzy_builder
[ -z $SOURCES_PATH ] && SOURCES_PATH=~/ws/src/mrs_lib
[ -z $REPOSITORY_NAME ] && REPOSITORY_NAME=mrs_lib

echo "SOURCES_PATH=$SOURCES_PATH"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "REPOSITORY_NAME=$REPOSITORY_NAME"

## | -------------------- derived variables ------------------- |

YAML_FILE=${REPO_PATH}/${LIST}.yaml

WORKSPACE_FOLDER=/tmp/workspace

## --------------------------------------------------------------
## |                  prepare the tester image                  |
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

## --------------------------------------------------------------
## |                    prepare the workspace                   |
## --------------------------------------------------------------

## | ---------------------- create the ws --------------------- |

echo "$0: creating the workspace"

if [ -e $WORKSPACE_FOLDER ]; then
  sudo rm -rf $WORKSPACE_FOLDER
fi

mkdir -p $WORKSPACE_FOLDER/src/repository

## | -------------------- update submodules ------------------- |

git submodule update --init --recursive

[[ -e .gitman.yml || -e .gitman.yaml ]] && gitman install || echo "no gitman modules to install"

cp -r $SOURCES_PATH/* $WORKSPACE_FOLDER/src/repository

## | ----------------- copy the testing script ---------------- |

cp $MY_PATH/entrypoint.sh $WORKSPACE_FOLDER/

## | ---------------------- run the test ---------------------- |

docker run \
  --rm \
  -v $WORKSPACE_FOLDER:/etc/docker/workspace \
  $DOCKER_IMAGE \
  /bin/bash -c "/etc/docker/workspace/entrypoint.sh $REPOSITORY_NAME"
