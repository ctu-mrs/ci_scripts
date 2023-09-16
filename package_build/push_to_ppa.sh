#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PPA=github.com/ctu-mrs/ppa-$1.git
FROM_FOLDER=$2

echo "$0: Deploying debs from $2 package to $PPA"

ARTIFACTS=$(find $FROM_FOLDER -type f -name "*.deb")

# remove temp files from buildfarm
[ -e $FROM_FOLDER/idx.txt ] && rm $FROM_FOLDER/idx.txt
[ -e $FROM_FOLDER/compiled.txt ] && rm $FROM_FOLDER/compiled.txt
[ -e $FROM_FOLDER/compile_further.txt ] && rm $FROM_FOLDER/compile_further.txt

echo "$0: artifacts are:"
echo $ARTIFACTS

cd /tmp
rm -rf ppa

git clone https://$PUSH_TOKEN@$PPA ppa

cd ppa

BRANCH=debs
git checkout $BRANCH

git config user.email github@github.com
git config user.name github

echo "$0: moving the .deb files"

# move the deb files
for FILE_PATH in `find $FROM_FOLDER -type f -name "*.deb"`; do

  PACKAGE_NAME=$(dpkg --field $FILE_PATH | grep "Package:" | head -n 1 | awk '{print $2}')
  ARCH=$(dpkg --field $FILE_PATH | grep "Architecture:" | head -n 1 | awk '{print $2}')

  echo "$0: Pushing the package '$FILE_PATH' to '$PPA', extracted pkg name: '$PACKAGE_NAME', architecture: '$ARCH'"

  if [[ "$1" == "unstable" ]]; then

    echo "$0: pushing to 'unstable', going to delete old versions"

    for file_to_delete in `ls | grep -e "${PACKAGE_NAME}_.*_${ARCH}.deb$"`; do

      echo "$0: deleting '$file_to_delete'"
      rm $file_to_delete

    done

  fi

  mv $FILE_PATH ./

done

# copy any other stuff that were generated
echo "$0: moving other files"
mv $FROM_FOLDER/* ./ || echo "$0: no more stuff to move"

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
