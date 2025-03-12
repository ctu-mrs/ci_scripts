#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

REPOSITORY_NAME=$1

WORKSPACE=/etc/docker/workspace

## | ---------------- initialize the workspace ---------------- |

echo "$0: installing dependencies using rosdep"

rosdep install -y -v --from-path $WORKSPACE/src

cd $WORKSPACE

source /opt/ros/jazzy/setup.bash
colcon build

source $WORKSPACE/install/setup.bash

## | --- run tests an all ros packages within the repository -- |

colcon test --base-paths $WORKSPACE/src/$REPOSITORY_NAME

colcon test-result --all --verbose

echo "$0: tests finished"
