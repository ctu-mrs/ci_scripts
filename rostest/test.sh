#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PACKAGE_FOLDER=$1
VARIANT=$2
WORKSPACE=/tmp/workspace

# needed for building open_vins
export ROS_VERSION=1

sudo apt-get -y install dpkg-dev

ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

# we already have a docker image with ros for the ARM build
if [[ "$ARCH" != "arm64" ]]; then
  curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ros_ppa.sh | bash
fi

curl https://ctu-mrs.github.io/ppa-$VARIANT/add_ppa.sh | bash

sudo apt-get -y -q install ros-noetic-desktop
sudo apt-get -y -q install ros-noetic-mrs-uav-system
sudo apt-get -y -q install lcov

sudo pip3 install -U gitman

mkdir -p $WORKSPACE/src

cd $WORKSPACE

source /opt/ros/noetic/setup.bash
catkin init

catkin config --profile debug --cmake-args -DCMAKE_BUILD_TYPE=Debug
catkin profile set debug

catkin build

## | ---------------- clone the tested package ---------------- |

cd $WORKSPACE/src

ln -s $PACKAGE_FOLDER $WORKSPACE/src

source $WORKSPACE/devel/setup.bash

echo "$0: installing rosdep dependencies"

rosdep install --from-path .

echo "$0: building the workspace"

catkin build --limit-status-rate 0.2 --cmake-args -DCOVERAGE=true -DMRS_ENABLE_TESTING=true
catkin build --limit-status-rate 0.2 --cmake-args -DCOVERAGE=true -DMRS_ENABLE_TESTING=true --catkin-make-args tests

echo "$0: testing"

cd $WORKSPACE/src
ROS_DIRS=$(find . -name package.xml -printf "%h\n")

for DIR in $ROS_DIRS; do
  cd $WORKSPACE/src/$DIR
  catkin test --this -p 1 -s
done

echo "$0: tests finished"
