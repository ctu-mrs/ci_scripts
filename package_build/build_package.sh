#!/bin/bash

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PACKAGE_FOLDER=$1
ARTIFACTS_FOLDER=$2

echo "$0: building packages from '$PACKAGE_FOLDER' into '$ARTIFACTS_FOLDER'"

mkdir -p $ARTIFACTS_FOLDER

$MY_PATH/install_ros.sh

echo "$0: Building the package"

cd $PACKAGE_FOLDER

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

cd $PACKAGE_FOLDER

# find all package.xml files
PACKAGES=$(find . -name "package.xml")

for PACKAGE in $PACKAGES; do

  PACKAGE_PATH=$(echo "$PACKAGE" | sed -e 's/\/package.xml$//g')

  ## don't run if CATKIN_IGNORE is present

  [ -e $PACKAGE_PATH/CATKIN_IGNORE ] && continue

  ## don't run for nested packages

  NESTED=false

  for PACKAGE2 in $PACKAGES; do

    PACKAGE2_PATH=$(echo "$PACKAGE2" | sed -e 's/\/package.xml$//g')

    [[ "$PACKAGE" == "$PACKAGE2" ]] && continue

    if [[ $PACKAGE_PATH == $PACKAGE2_PATH* ]]; then

      NESTED=true
      break

    fi

  done

  $NESTED && continue

  echo "$0: cding to '$PACKAGE_FOLDER/$PACKAGE_PATH'"

  cd $PACKAGE_FOLDER/$PACKAGE_PATH

  rosdep install -y -v --rosdistro=noetic --from-paths ./

  echo "$0: Running bloom on a package in '$PACKAGE_PATH'"

  export DEB_BUILD_OPTIONS="parallel=`nproc`"
  bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

  echo "$0: calling build on '$PACKAGE_PATH'"

  fakeroot debian/rules "binary --parallel"

  echo "$0: finished building '$PACKAGE'"

  mv ../*.deb $ARTIFACTS_FOLDER

done

echo "$0: Build finished"
