#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

REPOSITORY_NAME=$1

WORKSPACE=/etc/docker/workspace
COVERAGE=/etc/docker/coverage
COREDUMP=/etc/docker/coredump

## | ---------------- initialize the workspace ---------------- |

if [ ! -e $WORKSPACE/devel ]; then

  echo "$0: workspace not initialized, initializing"

  cd $WORKSPACE

  source /opt/ros/jazzy/setup.bash
  colcon build

  # catkin config --profile debug --cmake-args -DCMAKE_BUILD_TYPE=Debug
  # catkin profile set debug

  echo "$0: installing dependencies using rosdep"

  rosdep install -y -v --from-path src/

fi

## | ------------------- build the workspace ------------------ |

echo "$0: building the workspace"

cd $WORKSPACE

colcon build

source $WORKSPACE/devel/setup.bash

## | --- run tests an all ros packages within the repository -- |

cd $WORKSPACE/src/$REPOSITORY_NAME
FAILED=0

colcon test --base-paths $WORKSPACE/src/$REPOSITORY_NAME || FAILED=1

colcon test-result --all --verbose

echo "$0: tests finished"

## | ---------------------- save coverage --------------------- |

if [[ "$FAILED" -eq 0 ]]; then

  echo "$0: storing coverage data"

  # gather all the coverage data from the workspace
  lcov --capture --directory ${WORKSPACE} --output-file /tmp/coverage.original

  # filter out unwanted files, i.e., test files
  lcov --remove /tmp/coverage.original "*/test/*" --output-file /tmp/coverage.removed || echo "$0: coverage tracefile is empty"

  # extract coverage data for the source folder of the workspace
  lcov --extract /tmp/coverage.removed "$WORKSPACE/src/*" --output-file $COVERAGE/$REPOSITORY_NAME.info || echo "$0: coverage tracefile is empty"

fi

exit $FAILED
