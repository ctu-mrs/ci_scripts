#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

echo "$0: Deploying the deb package to CTU-MRS PPA"

# TODO check if we are on a tag
# git describe --exact-match --tags HEAD

ORIGINAL_DIR=`pwd`

cd /tmp

BRANCH=master
git clone https://$PUSH_TOKEN@github.com/ctu-mrs/ppa-unstable.git
cd ppa-unstable

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
