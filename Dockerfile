# We need the CUDA base dockerfile to enable GPU rendering
# on hosts with GPUs.
# The image below is a pinned version of nvidia/cuda:9.1-cudnn7-devel-ubuntu16.04 (from Jan 2018)
# If updating the base image, be sure to test on GPU since it has broken in the past.
FROM nvcr.io/nvidia/cuda:11.6.0-devel-ubuntu20.04

RUN apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    libgl1-mesa-dev \
    libgl1-mesa-glx \
    libglew-dev \
    libosmesa6-dev \
    software-properties-common \
    net-tools \
    vim \
    virtualenv \
    wget \
    patchelf \
    xpra \
    python3-pip \
    xserver-xorg-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.mujoco \
    && wget https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz -O mujoco.tar.gz \
    && tar -xf mujoco.tar.gz -C /root/.mujoco \
    && rm mujoco.tar.gz

ENV LD_LIBRARY_PATH /root/.mujoco/mujoco210/bin:${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

#COPY vendor/Xdummy /usr/local/bin/Xdummy
#RUN chmod +x /usr/local/bin/Xdummy

# Workaround for https://bugs.launchpad.net/ubuntu/+source/nvidia-graphics-drivers-375/+bug/1674677
#COPY ./vendor/10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

WORKDIR /mujoco_py
# Copy over just requirements.txt at first. That way, the Docker cache doesn't
# expire until we actually change the requirements.
COPY ./requirements.txt /mujoco_py/
COPY ./requirements.dev.txt /mujoco_py/
#RUN apt-get install python3-pip
RUN pip3 install --no-cache-dir -r /mujoco_py/requirements.txt
RUN pip3 install --no-cache-dir -r /mujoco_py/requirements.dev.txt

# Delay moving in the entire code until the very end.
#ENTRYPOINT ["/mujoco_py/vendor/Xdummy-entrypoint"]
#CMD ["pytest"]
COPY . /mujoco_py
RUN python3 setup.py install 
RUN python3 -c "exec(\"import mujoco_py\")"
