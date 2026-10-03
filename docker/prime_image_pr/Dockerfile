ARG BASE_IMAGE=set_from_outside
ARG PPA_VARIANT=set_from_outside

FROM $BASE_IMAGE

ARG PPA_VARIANT

# Install mesa-vulkan-drivers to provide Lavapipe (Vulkan software rendering)
RUN --mount=type=bind,source=add_private_ppa.sh,target=/tmp/add_private_ppa.sh \
  --mount=type=secret,id=PRIVATE_PPA_TOKEN,required=false \
  if [ -s /run/secrets/PRIVATE_PPA_TOKEN ]; then \
  PRIVATE_PPA_TOKEN="$(cat /run/secrets/PRIVATE_PPA_TOKEN)" bash /tmp/add_private_ppa.sh; \
  fi && \
  apt-get update && curl https://ctu-mrs.github.io/ppa2-${PPA_VARIANT}/add_ppa.sh | bash && \
  apt-get --no-install-recommends -y install ros-${ROS_DISTRO}-mrs-uav-system-full \
  keyboard-configuration software-properties-common python3-bloom fakeroot \
  debhelper dh-python git aptitude mesa-vulkan-drivers && \
  apt-get clean && rm -rf /var/lib/apt/lists/*
