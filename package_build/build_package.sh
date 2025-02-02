#!/bin/bash

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

# needed for building open_vins
export ROS_VERSION=1

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PACKAGE_FOLDER=$1
ARTIFACTS_FOLDER=$2
WORKSPACE=/tmp/workspace
ARTIFACTS_FOLDER=/tmp/artifacts

ROSDEP_FILE=/tmp/generated.yaml
sudo rm -rf $ROSDEP_FILE

echo "$0: building packages from '$PACKAGE_FOLDER' into '$ARTIFACTS_FOLDER'"

mkdir -p $ARTIFACTS_FOLDER

sudo apt-get -y install dpkg-dev
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" == "arm64" ]]; then

  echo "$0: arm64 architecture detected"

elif [[ "$ARCH" == "armhf" ]]; then

  echo "$0: armhf architecture detected"

  export SSL_CERT_FILE=/usr/lib/ssl/certs/ca-certificates.crt

  sudo c_rehash /etc/ssl/certs

  $MY_PATH/add_ros_ppa.sh

else

  echo "$0: probably amd64 architecture"

  $MY_PATH/add_ros_ppa.sh
fi

# dependencies need for build the deb package
sudo apt-get -y install ros-noetic-catkin python3-catkin-tools
sudo apt-get -y install fakeroot dpkg-dev debhelper
sudo pip3 install -U bloom future

cd $PACKAGE_FOLDER

echo "$0: updating git submodules"
git submodule update --init --recursive

[ -d $WORKSPACE ] && rm -rf $WORKSPACE
mkdir -p $WORKSPACE

cd $WORKSPACE
mkdir src
source /opt/ros/noetic/setup.bash
catkin init

echo "$0: Building the package"

curl https://ctu-mrs.github.io/ppa-unstable/add_ppa.sh | bash

ln -s $PACKAGE_FOLDER $WORKSPACE/src

cd $WORKSPACE

BUILD_ORDER=$(catkin list -u)

echo ""
echo "$0: catkin reported following topological build order:"
echo "$BUILD_ORDER"
echo ""

echo "yaml file://$ROSDEP_FILE" | sudo tee /etc/ros/rosdep/sources.list.d/temp.list

for PACKAGE in $BUILD_ORDER; do

  PKG_PATH=$(catkin locate $PACKAGE)

  echo "$0: cding to '$PKG_PATH'"
  cd $PKG_PATH

  ## don't run if CATKIN_IGNORE is present

  [ -e $PKG_PATH/CATKIN_IGNORE ] && continue

  rosdep install -y -v --rosdistro=noetic --dependency-types=build --from-paths ./
  sudo apt-get -y install python-is-python3

  source /opt/ros/noetic/setup.bash

  echo "$0: Running bloom on a package in '$PKG_PATH'"

  if [[ "$ARCH" != "arm64" ]]; then
    export DEB_BUILD_OPTIONS="parallel=`nproc`"
  fi

  bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

  SHA=$(git rev-parse --short HEAD)

  epoch=2
  build_flag="$(date +%Y%m%d.%H%M%S)~on.push.build.git.$SHA"

  sed -i "s/(/($epoch:/" ./debian/changelog
  sed -i "s/)/.${build_flag})/" ./debian/changelog

  echo "$0: calling build on '$PKG_PATH'"

  if [[ "$ARCH" != "arm64" ]]; then
    fakeroot debian/rules "binary --parallel"
  else
    fakeroot debian/rules "binary"
  fi

  echo "$0: finished building '$PACKAGE'"

  FIND_METAPACKAGE=$(cat CMakeLists.txt | grep -e "^catkin_metapackage" | wc -l)

  if [ $FIND_METAPACKAGE -eq 0 ]; then
    sudo apt-get -y install --allow-downgrades ../*.deb
  fi

  DEB_NAME=$(dpkg --field ../*.deb | grep "^Package:" | head -n 1 | awk '{print $2}')
  mv ../*.deb $ARTIFACTS_FOLDER

  echo "$PACKAGE:
  ubuntu: [$DEB_NAME]
" >> $ROSDEP_FILE

  rosdep update

  source /opt/ros/noetic/setup.bash

done

echo "$0: Build finished"
