#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Deploying the deb package to CTU-MRS PPA"

ORIGINAL_DIR=`pwd`

cd /tmp

git clone https://$PUSH_TOKEN@github.com/ctu-mrs/ppa.git

cd ppa

git config user.email github@github.com
git config user.name github

mv $ORIGINAL_DIR/../*.deb ./
mv $ORIGINAL_DIR/../*.ddeb ./

git add -A
git commit -m "Added new deb packages"
git push

echo "$0: package deployed"
