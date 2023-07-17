#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PPA=github.com/ctu-mrs/ppa-$1.git

echo "$0: Deploying the deb package to $PPA"

cd /tmp
rm -rf ppa

git clone https://$PUSH_TOKEN@$PPA ppa

cd ppa

# TODO: will need to be reworked when we start building for ARM
ARCH=amd64

BRANCH=master
git checkout $BRANCH

git config user.email github@github.com
git config user.name github

if [ "$1" == "unstable" ]; then

  PACKAGE_NAME=$(cat $GITHUB_WORKSPACE/debian/control | grep Package | awk '{print $2}')
  echo "$0: Package name: $PACKAGE_NAME"

  rm "$PACKAGE_NAME"_*"$ARCH".deb || echo "$0: there are no older *.deb packages to remove"
  rm "$PACKAGE_NAME"-dbgsym_*"$ARCH".ddeb || echo "$0: there are no older *.ddeb packages to remove"

fi

cp $GITHUB_WORKSPACE/../*.deb ./
cp $GITHUB_WORKSPACE/../*.ddeb ./

GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then

  git add -A
  git commit -m "Added new deb packages"

  # the upstream might have changed in the meantime, try to merge it first
  git fetch
  git merge origin/$BRANCH

  git push

  echo "$0: Package deployed to $PPA"

else

  echo "$0: Nothing to commit"

fi
