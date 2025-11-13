#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# determine our architecture
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)

##########################

DEBS_FOLDER=/etc/docker/debs
REPO_FOLDER=/etc/docker/repository
OTHER_FILES_FOLDER=/etc/docker/other_files

git config --global --add safe.directory /etc/docker/repository

BUILD_ORDER=$(cat /etc/docker/other_files/build_order.txt)

echo ""
echo "$0: build order:"
echo "$BUILD_ORDER"
echo ""

ROSDEP_FILE=/tmp/rosdep.yaml
touch $ROSDEP_FILE
echo "yaml file://$ROSDEP_FILE" | tee /etc/ros/rosdep/sources.list.d/temp.list

OLDIFS=$IFS; IFS=$'\n'; for LINE in $BUILD_ORDER; do

  PACKAGE=$(echo $LINE | awk '{print $1}')
  PKG_PATH=$(echo $LINE | awk '{print $2}')

  echo "$0: cding to '$REPO_FOLDER/$PKG_PATH'"
  cd $REPO_FOLDER/$PKG_PATH

  FUTURE_DEB_NAME=$(echo "ros-jazzy-$PACKAGE" | sed 's/_/-/g')

  echo "$0: future deb name: $FUTURE_DEB_NAME"

  git config --global --add safe.directory $REPO_FOLDER/$PKG_PATH

  SHA=$(git rev-parse --short HEAD)
  DOCKER_SHA=$(cat $OTHER_FILES_FOLDER/base_sha.txt)

  ## don't run if COLCON_IGNORE is present

  [ -e $PKG_PATH/COLCON_IGNORE ] && continue

  apt-get -y update

  rosdep install -y -v --rosdistro=jazzy --dependency-types=build --dependency-types=buildtool --from-paths ./

  source /opt/ros/jazzy/setup.bash

  # Tests are run only on demand. Set RUN_TESTS=1 or RUN_TESTS=true (or yes) in the environment to enable.
  if [ "${RUN_TESTS:-0}" = "1" ] || [[ "${RUN_TESTS:-}" =~ ^(true|yes)$ ]]; then
    echo "$0: RUN_TESTS enabled; building and testing package '$PACKAGE'"

    # build only the current package; add parallelism on non-arm64
    if [[ "$ARCH" != "arm64" ]]; then
      colcon build --packages-select "$PACKAGE" --parallel-workers "$(nproc)" --cmake-args -DCMAKE_BUILD_TYPE=Release
    else
      colcon build --packages-select "$PACKAGE" --cmake-args -DCMAKE_BUILD_TYPE=Release
    fi

    # source install before running tests so runtime environment is set up
    if [ -f install/setup.bash ]; then
      source install/setup.bash
    fi

    echo "$0: Running tests for '$PACKAGE'"
    set +e # Temporarily DISABLE set -e
    colcon test --packages-select $PACKAGE --event-handlers console_cohesion+
    TEST_EXIT_CODE=$? # Capture the exit code immediately
    set -e # RE-ENABLE set -e

    # print/propagate test results
    colcon test-result --all --verbose

    # Now you can optionally re-check the exit code and decide what to do
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        exit $TEST_EXIT_CODE
    fi
  else
    echo "$0: RUN_TESTS not set; skipping colcon build/test for '$PACKAGE'"
  fi

  echo "$0: Running bloom on a package in '$PKG_PATH'"

  if [[ "$ARCH" != "arm64" ]]; then
    export DEB_BUILD_OPTIONS="parallel=`nproc`"
  fi

  bloom-generate rosdebian --os-name ubuntu --os-version noble --ros-distro jazzy

  epoch=2

  build_flag="$(date +%Y%m%d.%H%M%S)~on.push.build.git.$SHA.base.$DOCKER_SHA"

  sed -i "s/(/($epoch:/" ./debian/changelog
  sed -i "s/)/.${build_flag})/" ./debian/changelog

  if [[ "$ARCH" != "arm64" ]]; then
    fakeroot debian/rules "binary --parallel"
  else
    fakeroot debian/rules "binary"
  fi

  DEB_NAME=$(dpkg --field ../*.deb | grep "Package:" | head -n 1 | awk '{print $2}')

  DEBS=(../*.deb)

  echo "$0: installing newly compiled deb file"
  [ -e "${DEBS[0]}" ] && apt-get -y install --allow-downgrades ../*.deb || echo "$0: no artifacts to be installed"

  echo "$0: moving the artifact to $DEBS_FOLDER"
  [ -e "${DEBS[0]}" ] && mv ../*.deb $DEBS_FOLDER || echo "$0: no artifacts to be moved"

  echo "$PACKAGE:
  ubuntu: [$DEB_NAME]
" >> $ROSDEP_FILE

  rosdep update

  source /opt/ros/jazzy/setup.bash

  echo "$PACKAGE" >> $OTHER_FILES_FOLDER/compiled.txt

done

echo "$0: build finished"
