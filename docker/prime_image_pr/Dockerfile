ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

# Install mesa-vulkan-drivers to provide Lavapipe (Vulkan software rendering)
RUN apt-get update && curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash && \
    apt-get --no-install-recommends -y install ros-${ROS_DISTRO}-mrs-uav-system-full \
    keyboard-configuration software-properties-common python3-bloom fakeroot \
    debhelper dh-python git aptitude mesa-vulkan-drivers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
