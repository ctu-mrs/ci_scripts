#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

REPOSITORY_NAME=$1

WORKSPACE=/etc/docker/workspace

## | ---------------- initialize the workspace ---------------- |

echo "::group::dependency installation"

echo "$0: installing dependencies using rosdep"

git config --global --add safe.directory /etc/docker/workspace/src/repository

apt-get update

## get up-to-date lists for resolving ROS package.xml depencies
rosdep --rosdistro=$ROS_DISTRO update

rosdep install -y -v --rosdistro=$ROS_DISTRO --from-path $WORKSPACE/src --ignore-src || echo "$0: failed to install dependencies using rosdep, the build might fail"

echo "::endgroup::"

## | -------------------- build the package ------------------- |
#
echo "$0: building the workspace"

echo "::group::build"

cd $WORKSPACE

source /opt/ros/$ROS_DISTRO/setup.bash

colcon build --symlink-install --cmake-args -DENABLE_TESTS=true

source $WORKSPACE/install/setup.bash

## | --- run tests an all ros packages within the repository -- |

echo "::endgroup::"

echo "$0: running the tests"

echo "::group::test"

cd $WORKSPACE

FAILED=0

colcon test-result --delete-yes

pkgs=$(colcon list -n)

export RMW_IMPLEMENTATION=rmw_zenoh_cpp

colcon test --executor sequential --ctest-args --packages-select $pkgs

echo "::endgroup::"

echo "::group::results"

colcon test-result --all --verbose || FAILED=1

echo "::endgroup::"

echo "$0: tests finished"

exit $FAILED
