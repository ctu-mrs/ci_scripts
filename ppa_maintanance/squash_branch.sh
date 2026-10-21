#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

PPA=$1
BRANCH=$2

cd /tmp

git clone --depth 1 --branch $BRANCH https://$PUSH_TOKEN@$PPA repo
cd repo

git config http.https://github.com/.extraheader "AUTHORIZATION: basic $(printf "x-access-token:%s" "$PUSH_TOKEN" | base64 | tr -d '\r\n')"
git config user.email github@github.com
git config user.name github

git checkout --orphan temp
git commit -m "Updated packages (squashed)"
git push origin temp:$BRANCH --force

echo "$0: $BRANCH squashed"
