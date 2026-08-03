ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

RUN apt-get update && curl https://ctu-mrs.github.io/ppa-${PPA_VARIANT}/add_ppa.sh | bash && \
    apt-get --no-install-recommends -y install keyboard-configuration software-properties-common \
    python3-pip fakeroot ros-noetic-catkin python3-catkin-tools python-is-python3 debhelper git lcov aptitude && \
    pip3 install -U bloom && apt-get clean && rm -rf /var/lib/apt/lists/*
