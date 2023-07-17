#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PPA=github.com/ctu-mrs/ppa-$1

cd /tmp

git clone https://$PUSH_TOKEN@$PPA repo
cd repo

git config user.email github@github.com
git config user.name github

git checkout master
git checkout --orphan new_master
git commit -m "Updated packages (squashed)"
git push origin new_master:master --force

echo "$0: Master squashed"
