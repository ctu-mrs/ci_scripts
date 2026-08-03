ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

# install ROS packages, Dev tools and mesa-vulkan-drivers to provide Lavapipe (Vulkan software rendering)
RUN apt-get update && curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash && \
    apt-get --no-install-recommends -y install ros-${ROS_DISTRO}-mrs-uav-core \
    keyboard-configuration software-properties-common python3-pip python3-bloom fakeroot \
    debhelper dh-python git aptitude wget mesa-vulkan-drivers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
