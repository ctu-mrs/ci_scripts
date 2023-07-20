#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

LABEL=$1
MODE=$2

echo "$RELEASE_KEY" | gpg --import

sudo apt -y update
sudo apt -y install dpkg-dev # needed for dpng-scanpackages
sudo apt -y install apt-utils # needed for apt-ftparchive

if [ "$MODE" == "from-master-branch" ]; then

  # mv .debs/*.ddeb ./
  mv .debs/*.deb ./
  mv resources/apt/* ./
  mv resources/rosdep/* ./
  rm -rf resources

elif [ "$MODE" == "from-debs-branch" ]; then

  mv .master/resources/apt/* ./
  mv .master/resources/rosdep/* ./

else

  echo "$0: Please select a mode, {from-master-branch, from-debs-branch}"

fi

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg & InRelease
apt-ftparchive \
  -o "APT::FTPArchive::Release::Origin=ctu-mrs" \
  -o "APT::FTPArchive::Release::Label=$LABEL" \
  release . > Release
gpg --default-key "tomas.baca@fel.cvut.cz" -abs -o - Release > Release.gpg
gpg --default-key "tomas.baca@fel.cvut.cz" --clearsign -o - Release > InRelease
