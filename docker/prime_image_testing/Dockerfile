ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

# Set environment variables once (replaces the interactive workaround lines)
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    bash \
    keyboard-configuration \
    # Install the PPA
    && curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash \
    # Install ROS packages and Dev tools
    && apt-get install -y --no-install-recommends \
    ros-jazzy-mrs-uav-core \
    fakeroot \
    debhelper \
    python3-pip \
    python3-bloom \
    python3-rosdep \
    dpkg-dev \
    git \
    aptitude \
    wget \
    # Install mesa-vulkan-drivers to provide Lavapipe (Vulkan software rendering)
    mesa-vulkan-drivers \
    # CLEANUP: This is the most important step for compression
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
