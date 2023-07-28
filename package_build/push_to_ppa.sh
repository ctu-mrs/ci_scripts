#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PPA=github.com/ctu-mrs/ppa-$1.git
FROM_FOLDER=$2

echo "$0: Deploying debs from $2 package to $PPA"

cd /tmp
rm -rf ppa

git clone https://$PUSH_TOKEN@$PPA ppa

cd ppa

BRANCH=debs
git checkout $BRANCH

git config user.email github@github.com
git config user.name github

# copy the deb files
for FILE in `ls $FROM_FOLDER | grep -e ".deb$"`; do

  FILE_PATH=$FROM_FOLDER/$FILE

  PACKAGE_NAME=$(dpkg --field $FILE_PATH | grep Package | awk '{print $2}')
  ARCH=$(dpkg --field $FILE_PATH | grep Architecture | awk '{print $2}')

  echo "$0: Pushing the package '$FILE_PATH' to '$PPA', extracted pkg name: '$PACKAGE_NAME', architecture: '$ARCH'"

  if [[ "$PPA" == "unstable" ]]; then

    # remove old versions of that package
    rm $PACKAGE_NAME.*$ARCH.deb || echo ""

  fi

  cp $FILE_PATH ./

done

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
