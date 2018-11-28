# FROM nvidia/opengl:1.0-glvnd-devel 
FROM ubuntu:16.04

ARG USER
ARG USER_UID
ARG USER_GID
ARG ROS_MASTER_URI

ENV QT_VERSION v5.9.1
ENV QT_CREATOR_VERSION v4.3.1

USER root

RUN userdel user || true
RUN groupdel user || true
RUN groupdel ${USER} || true
RUN groupadd -g 1000 ${USER} || true

RUN userdel ${USER} || true
RUN useradd -G video -s /bin/bash -u 1000 -g 1000 ${USER} || true

COPY ./sources.list /etc/apt/sources.list

RUN /bin/bash -c 'echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list'

# Other useful tools
RUN apt-get update
RUN apt-get -y install tmux wget zip git vim cmake cmake-qt-gui wget
RUN wget -O /usr/share/keyrings/ros-osrf.gpg https://github.com/ros/rosdistro/raw/master/ros.key

RUN apt-get -y upgrade

RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
    echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDA_VERSION 9.1.85

ENV CUDA_PKG_VERSION 9-1=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-9.1 /usr/local/cuda

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# Build prerequisites
RUN DEBIAN_FRONTEND=noninteractive apt-get -y build-dep qtbase-opensource-src
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libxcb-xinerama0-dev libqt5opengl5-dev qtbase5-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libboost-filesystem-dev libboost-locale-dev libboost-program-options-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libogre-1.9.0v5 libogre-1.9-dev libogre-1.9.0v5-dbg

# ROS base
RUN DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ros-kinetic-ros-base

# Simple root password in case we want to customize the container
RUN echo "root:root" | chpasswd

# Qt Creator
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install qtcreator
ADD entrypoint_qtcreator.sh /usr/local/bin/entrypoint.sh

RUN DEBIAN_FRONTEND=noninteractive apt-get -y build-dep libsofa1
RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install libassimp-dev libpython3-dev cuda-tools-9-1 cuda-toolkit-9-1 libogre-1.9-dev bison flex libpng-dev sudo iputils-ping

RUN chmod +x /usr/local/bin/entrypoint.sh

RUN usermod -a -G sudo ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN mkdir -p /home/${USER}
RUN chown ${USER}.${USER} /home/${USER} -R

USER ${USER}	

WORKDIR /home/${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
