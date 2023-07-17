#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Deploying the deb package to CTU-MRS PPA"

ORIGINAL_DIR=`pwd`

GIT_TAG=$(git describe --exact-match --tags HEAD)

if [ $? == "0" ]; then

  echo "$0: Git tag recognized as '$GIT_TAG', deploying to stable PPA"

  git clone https://$PUSH_TOKEN@github.com/ctu-mrs/ppa-stable.git ppa

else

  echo "$0: Git tag not recognized, deploying to unstable PPA"

  git clone https://$PUSH_TOKEN@github.com/ctu-mrs/ppa-unstable.git ppa

fi

cd /tmp

BRANCH=master
cd ppa

git checkout $BRANCH

git config user.email github@github.com
git config user.name github

mv $ORIGINAL_DIR/../*.deb ./
mv $ORIGINAL_DIR/../*.ddeb ./

GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then

  git add -A
  git commit -m "Added new deb packages"

  # the upstream might have changed in the meantime, try to merge it first
  git fetch
  git merge origin/$BRANCH

  git push

  echo "$0: Package deployed"

else

  echo "$0: Nothing to commit"

fi
