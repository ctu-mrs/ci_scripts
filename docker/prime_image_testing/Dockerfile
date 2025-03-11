ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

RUN apt-get -y update

# workaround interractive prompts during apt installations
RUN echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install keyboard-configuration

RUN apt-get -y install software-properties-common curl bash

RUN curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash

RUN apt-get -y install ros-jazzy-mrs-uav-system-full

RUN apt-get -y install fakeroot debhelper python3-pip python3-bloom python3-rosdep dpkg-dev git lcov aptitude
