#!/bin/bash

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Building the package"

cd $GITHUB_WORKSPACE

GIT_TAG=$(git describe --exact-match --tags HEAD || echo "")

if [ -z $GIT_TAG ]; then

  echo "$0: Git tag not recognized, building against unstable PPA"

  $MY_PATH/add_ctu_mrs_unstable_ppa.sh

else

  echo "$0: Git tag recognized as '$GIT_TAG', building against stable PPA"

  $MY_PATH/add_ctu_mrs_stable_ppa.sh

fi

sudo apt-get -y install fakeroot dpkg-dev debhelper

sudo pip3 install -U bloom

cd $GITHUB_WORKSPACE

rosdep install -y -v --rosdistro=noetic --from-paths ./

# bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic
# fakeroot debian/rules binary

PACKAGES=$( bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic | tee )

PACKAGES=$(echo "$PACKAGES" | grep -e "Expanding.*rules")

MY_PATH=`pwd`

for ONE_LINE in "$PACKAGES"; do

  echo "$0: Going to build a package related to '$ONE_LINE'"

  RELATIVE_PKG_PATH="$(echo "$ONE_LINE" | awk '{print $2}' | sed s/\'//g | sed -e 's/\/*debian\/rules.em//g' )"

  echo "$0: calling build on $RELATIVE_PKG_PATH"
  cd $MY_PATH/$RELATIVE_PKG_PATH

  fakeroot debian/rules binary

done

echo "$0: Build finished"
