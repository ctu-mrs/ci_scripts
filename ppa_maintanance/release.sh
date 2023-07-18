#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

LABEL=$1

echo "$RELEASE_KEY" | gpg --import

sudo apt -y update
sudo apt -y install dpkg-dev # needed for dpng-scanpackages
sudo apt -y install apt-utils # needed for apt-ftparchive

mv .debs/*.deb ./
mv .debs/*.ddeb ./

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
