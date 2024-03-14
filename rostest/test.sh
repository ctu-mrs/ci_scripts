#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PACKAGE_FOLDER=$1
VARIANT=$2
WORKSPACE=/tmp/workspace

# needed for building open_vins
export ROS_VERSION=1

sudo apt-get -y install dpkg-dev git-lfs

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

rosdep install -y --from-path .

echo "$0: building the workspace"

catkin build --limit-status-rate 0.2 --cmake-args -DMRS_ENABLE_TESTING=true
catkin build --limit-status-rate 0.2 --cmake-args -DMRS_ENABLE_TESTING=true --catkin-make-args tests

echo "$0: testing"

## set coredump generation

mkdir -p /tmp/coredump
sudo sysctl -w kernel.core_pattern="/tmp/coredump/%e_%p.core"
ulimit -c unlimited

cd $WORKSPACE/src
ROS_DIRS=$(find -L . -name package.xml -printf "%h\n")

FAILED=0

for DIR in $ROS_DIRS; do

  echo "$0: running test for '$DIR'"

  cd $WORKSPACE/src/$DIR
  catkin test --limit-status-rate 0.2 --this -p 1 -s || FAILED=1

done

echo "$0: tests finished"

ls /tmp/coredump

if [ -z "$(ls -A /tmp/coredump | grep .core)" ]; then
  exit $FAILED
else
  echo "$0: core dumps detected"
fi

cd /tmp
git clone https://$PUSH_TOKEN@github.com/ctu-mrs/buildfarm_coredumps
cd /tmp/buildfarm_coredumps

git config user.email github@github.com
git config user.name github

d="$(date +"%Y-%m-%d_%H.%M.%S")_${PACKAGE_FOLDER##*/}"
mkdir -p "$d"
cd "$d"
mv /tmp/coredump/* ./
cp -L $WORKSPACE/devel/lib/*.so ./
cd ..
tar -cvzf "$d.tar.gz" "$d"
rm -rf "$d"

git add -A
git commit -m "Added new coredumps"

# the upstream might have changed in the meantime, try to merge it first
git fetch
git merge origin/master

git push

echo "$0: core dumps pushed"

exit 1
