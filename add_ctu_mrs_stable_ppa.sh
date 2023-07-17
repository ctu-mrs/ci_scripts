#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Adding MRS Stable PPA repository"

curl -s --compressed "https://ctu-mrs.github.io/ppa-stable/ctu-mrs.gpg" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/ctu-mrs.gpg >/dev/null
sudo curl -s --compressed -o /etc/apt/sources.list.d/ctu-mrs.list "https://ctu-mrs.github.io/ppa-stable/ctu-mrs.list"
sudo curl -s --compressed -o /etc/ros/rosdep/sources.list.d/30-ctu-mrs.list "https://ctu-mrs.github.io/ppa-stable/rosdep/ctu-mrs.list"
sudo apt-get -y update

rosdep update

echo "$0: Finished adding MRS Stable PPA repository"
