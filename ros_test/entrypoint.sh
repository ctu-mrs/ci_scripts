#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

REPOSITORY_NAME=$1

WORKSPACE=/etc/docker/workspace

## | ---------------- initialize the workspace ---------------- |

echo "$0: installing dependencies using rosdep"

rosdep install -y -v --from-path $WORKSPACE/src || echo "$0: failed to install dependencies using rosdep, the build might fail"

## | -------------------- build the package ------------------- |
#
echo "$0: building the workspace"

cd $WORKSPACE

source /opt/ros/jazzy/setup.bash

colcon build --symlink-install --cmake-args -DENABLE_TESTS=true

source $WORKSPACE/install/setup.bash

## | --- run tests an all ros packages within the repository -- |

echo "$0: running the tests"

cd $WORKSPACE

FAILED=0

colcon test-result --delete-yes

pkgs=$(colcon list -n)

colcon test --executor sequential --ctest-args --packages-select $pkgs

colcon test-result --all --verbose || FAILED=1

echo "$0: tests finished"

exit $FAILED
