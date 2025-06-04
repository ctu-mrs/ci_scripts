ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

RUN apt-get -y update

# workaround interractive prompts during apt installations
RUN echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install keyboard-configuration

RUN apt-get -y install software-properties-common curl bash

RUN echo kocka

RUN curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash

RUN apt-get -y install ros-jazzy-mrs-uav-core

RUN apt-get -y install fakeroot debhelper python3-pip python3-bloom python3-rosdep dpkg-dev git aptitude wget perl

# compile lcov from sources (needs perl)
RUN perl -MCPAN -e 'install(Capture::Tiny)' && perl -MCPAN -e 'install(DateTime)'
RUN LCOV_VERSION=2.3.1 && cd /tmp && wget https://github.com/linux-test-project/lcov/releases/download/v$LCOV_VERSION/lcov-$LCOV_VERSION.tar.gz && tar -xvzf lcov-$LCOV_VERSION.tar.gz && cd lcov-$LCOV_VERSION && make install
