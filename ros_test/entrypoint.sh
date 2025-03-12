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

source /opt/ros/noetic/setup.bash
catkin build

source $WORKSPACE/devel/setup.bash

## | --- run tests an all ros packages within the repository -- |

colcon test --base-paths $WORKSPACE/src/$REPOSITORY_NAME

catkin test --limit-status-rate 0.2 -p 1 -s

echo "$0: tests finished"
