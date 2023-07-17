#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

echo "$0: Deploying the deb package to CTU-MRS PPA"

ORIGINAL_DIR=`pwd`

cd $GITHUB_WORKSPACE

GIT_TAG=$(git describe --exact-match --tags HEAD || echo "")

if [ $GIT_TAG == "" ]; then

  echo "$0: Git tag not recognized, deploying to unstable PPA"

  $MY_PATH/push_to_ppa.sh unstable

else

  echo "$0: Git tag recognized as '$GIT_TAG', deploying to stable PPA"

  $MY_PATH/push_to_ppa.sh stable

fi
