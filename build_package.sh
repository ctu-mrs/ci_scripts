#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Building the package"

sudo apt-get -y install fakeroot dpkg-dev debhelper

sudo pip3 install -U bloom

rosdep install -y -v --rosdistro=noetic --from-paths ./

bloom-generate rosdebian --os-name ubuntu --os-version focal --ros-distro noetic

fakeroot debian/rules binary

echo "$0: Build finished"
