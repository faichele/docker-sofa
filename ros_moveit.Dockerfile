FROM ubuntu:xenial

ARG NRP_USER
ARG NRP_NUM_PROCESSES
ARG ROS_MASTER_URI

#   Set enviroment to build from bitbucket
ENV NRP_INSTALL_MODE user
ENV HOME /home/${NRP_USER}
ENV NRP_ROS_VERSION kinetic
ENV ROS_DISTRO kinetic
ENV NRP_SOURCE_DIR /home/${NRP_USER}/nrp/src
ENV NRP_INSTALL_DIR /home/${NRP_USER}/.local
ENV HBP ${NRP_SOURCE_DIR}
ENV ROS_MASTER_URI ${ROS_MASTER_URI}

#   Set environment vars
ENV C_INCLUDE_PATH=${NRP_INSTALL_DIR}/include:$C_INCLUDE_PATH \
    CPLUS_INCLUDE_PATH=${NRP_INSTALL_DIR}/include:$CPLUS_INCLUDE_PATH \
    CPATH=${NRP_INSTALL_DIR}/include:$CPATH \
    LD_LIBRARY_PATH=${NRP_INSTALL_DIR}/lib:$LD_LIBRARY_PATH \
    PATH=${NRP_INSTALL_DIR}/bin:$PATH \
    VIRTUAL_ENV=${HOME}/.opt/platform_venv

USER root

RUN userdel user || true
RUN groupdel  user || true
RUN groupdel  ${NRP_USER} || true
RUN groupadd -g 1000 ${NRP_USER} || true

RUN userdel ${NRP_USER} || true
RUN useradd -s /bin/bash -u 1000 -g 1000 ${NRP_USER} || true

RUN mkdir -p ${HOME} || true
RUN mkdir -p ${NRP_SOURCE_DIR} || true
RUN mkdir -p ${NRP_INSTALL_DIR} || true
RUN mkdir -p ${NRP_SOURCE_DIR}/../platform_venv || true

COPY ./config/bashrc $HOME/.bashrc
RUN chown -R ${NRP_USER}.${NRP_USER} ${HOME}

COPY sources.list /etc/apt/sources.list

# Install prerequisites
RUN rm -rf /var/cache/apt/archives/* && apt-get update

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

RUN apt-get install -y sudo \
    autoconf automake \
    build-essential cmake \
    gfortran \
    git \
    ipython \
    libgsl0-dev libhdf5-dev liblapack-dev libblas-dev libltdl7-dev libpq-dev libqt4-dev libtool libxslt1-dev \
    python-all-dev python-matplotlib python-numpy python-pip python-scipy python-virtualenv \
    libncurses5-dev \
    libreadline6-dev \
    ssh net-tools \
    curl libcurl3 php-curl \
    cython python-mpi4py \
    nano xvfb libxv1 \
    software-properties-common python-software-properties \
    libffi-dev \
    pkg-config \
    bison byacc libtool-bin \
    nano vim logrotate \
    iputils-ping

WORKDIR ${HOME}/downloads
RUN wget --no-check-certificate downloads.sourceforge.net/project/virtualgl/2.5.1/virtualgl_2.5.1_amd64.deb \
    && dpkg -i virtualgl_2.5.1_amd64.deb \
    && sudo rm -rf virtualgl_2.5.1_amd64.deb

# add ros
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget\
    software-properties-common python-software-properties \
    python-rosdep python-rosinstall python-vcstools \
    locales

# setup environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# setup keys
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools

# bootstrap rosdep
RUN rosdep init \
    && rosdep update

# install ros packages
RUN apt-get update && apt-get install -y \
    ros-${NRP_ROS_VERSION}-ros-core

RUN apt-get update && apt-get install -y \
    ros-${NRP_ROS_VERSION}-ros-base

RUN apt-get update && \
    apt-get install -y --fix-missing ros-${NRP_ROS_VERSION}-control-toolbox \
    ros-${NRP_ROS_VERSION}-controller-manager \
    ros-${NRP_ROS_VERSION}-transmission-interface \
    ros-${NRP_ROS_VERSION}-joint-limits-interface \
    ros-${NRP_ROS_VERSION}-rosauth \
    ros-${NRP_ROS_VERSION}-smach-ros \
    ros-${NRP_ROS_VERSION}-rosauth \
    ros-${NRP_ROS_VERSION}-web-video-server

# Clone repos
WORKDIR ${NRP_SOURCE_DIR}
RUN git clone https://bitbucket.org/hbpneurorobotics/user-scripts

RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/sdformat.git"
RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/bulletphysics.git"
RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/simbody.git"
RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/opensim.git"
RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/gazebo.git"
RUN /bin/bash -c "git clone https://bitbucket.org/hbpneurorobotics/GazeboRosPackages.git"

# Install Gazebo prerequisites
RUN wget -O - http://packages.osrfoundation.org/gazebo.key | apt-key add -
RUN apt-add-repository "deb http://packages.osrfoundation.org/gazebo/ubuntu xenial main"

RUN apt-get update && \
    apt-get install --no-install-recommends -y wget \
    libignition-math2-dev \
    libignition-transport-dev \
    libignition-transport0-dev \
    libboost-all-dev libtinyxml-dev libtinyxml2-dev ruby protobuf-compiler\
    && pip install psutil

RUN apt-get install -y libogre-1.9.0v5 libogre-1.9-dev

# Install GazeboRosPackages prerequisites
RUN apt-get install -y \
    ros-${NRP_ROS_VERSION}-sensor-msgs \
    ros-${NRP_ROS_VERSION}-angles \
    ros-${NRP_ROS_VERSION}-tf \
    ros-${NRP_ROS_VERSION}-image-transport \
    ros-${NRP_ROS_VERSION}-cv-bridge \
    ros-${NRP_ROS_VERSION}-control-toolbox \
    ros-${NRP_ROS_VERSION}-controller-manager \
    ros-${NRP_ROS_VERSION}-transmission-interface \
    ros-${NRP_ROS_VERSION}-joint-limits-interface \
    ros-${NRP_ROS_VERSION}-polled-camera \
    ros-${NRP_ROS_VERSION}-diagnostic-updater \
    ros-${NRP_ROS_VERSION}-rosbridge-server \
    ros-${NRP_ROS_VERSION}-camera-info-manager \
    ros-${NRP_ROS_VERSION}-xacro

# Compile and install sdformat
RUN mkdir -p ${NRP_SOURCE_DIR}/sdformat/build
WORKDIR ${NRP_SOURCE_DIR}/sdformat/build
RUN cmake -DCMAKE_INSTALL_PREFIX=${NRP_INSTALL_DIR} ${NRP_SOURCE_DIR}/sdformat
RUN make -j4
RUN make install

# Compile and install bulletphysics
RUN mkdir -p ${NRP_SOURCE_DIR}/bulletphysics/build
WORKDIR ${NRP_SOURCE_DIR}/bulletphysics/build
RUN cmake -DCMAKE_INSTALL_PREFIX=${NRP_INSTALL_DIR} ${NRP_SOURCE_DIR}/bulletphysics
RUN make -j4
RUN make install

# Compile and install SimBody
RUN mkdir -p ${NRP_SOURCE_DIR}/simbody/build
WORKDIR ${NRP_SOURCE_DIR}/simbody/build
RUN cmake -DCMAKE_INSTALL_PREFIX=${NRP_INSTALL_DIR} ${NRP_SOURCE_DIR}/simbody
RUN make -j4
RUN make install

# Compile and install OpenSim
RUN mkdir -p ${NRP_SOURCE_DIR}/opensim/build
WORKDIR ${NRP_SOURCE_DIR}/opensim/build
RUN cmake -DCMAKE_INSTALL_PREFIX=${NRP_INSTALL_DIR} ${NRP_SOURCE_DIR}/opensim
RUN make -j4
RUN make install

# Compile and install Gazebo
RUN mkdir -p ${NRP_SOURCE_DIR}/gazebo/build
WORKDIR ${NRP_SOURCE_DIR}/gazebo/build
RUN apt-get update && apt-get install -y libogre-1.9-dev xsltproc libqtwebkit-dev libfreeimage-dev libtar-dev libprotoc-dev libtbb-dev libcurl4-openssl-dev
RUN cmake -DCMAKE_INSTALL_PREFIX=${NRP_INSTALL_DIR} -DENABLE_TESTS_COMPILATION:BOOL=False ${NRP_SOURCE_DIR}/gazebo
RUN make -j4
RUN make install

# Install GazeboRosPackages
ENV CMAKE_PREFIX_PATH ${NRP_INSTALL_DIR}/lib/cmake/gazebo/:$CMAKE_PREFIX_PATH
WORKDIR ${NRP_SOURCE_DIR}/GazeboRosPackages
ENV LD_LIBRARY_PATH ${NRP_INSTALL_DIR}/lib:$LD_LIBRARY_PATH
ENV CMAKE_PREFIX_PATH ${NRP_INSTALL_DIR}/lib/cmake/gazebo:${NRP_INSTALL_DIR}/lib/cmake/sdformat:$CMAKE_PREFIX_PATH
RUN /bin/bash -c "source ${NRP_INSTALL_DIR}/share/gazebo/setup.sh \
    && source /opt/ros/${NRP_ROS_VERSION}/setup.bash \
    && catkin_make --make-args -j4"

ENV CATKIN_WS=/home/${NRP_USER}/ws_moveit
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS/src

# Download moveit source
RUN wstool init . && \
    wstool merge https://raw.githubusercontent.com/ros-planning/moveit/${ROS_DISTRO}-devel/moveit.rosinstall && \
    wstool update

COPY ./config/trac_ik.rosinstall /home/${NRP_USER}/trac_ik.rosinstall
COPY ./config/bio_ik.rosinstall /home/${NRP_USER}/bio_ik.rosinstall
COPY ./config/ur_modern_driver.rosinstall /home/${NRP_USER}/ur_modern_driver.rosinstall
RUN wstool merge /home/${NRP_USER}/trac_ik.rosinstall && \
    wstool merge /home/${NRP_USER}/bio_ik.rosinstall && \
    wstool merge /home/${NRP_USER}/ur_modern_driver.rosinstall && \
    wstool update

# Update apt-get because osrf image clears this cache. download deps
# Note that because we're building on top of kinetic-ci, there should not be any deps installed
# unless something has changed in the source code since the other container was made
# (they are triggered together so should only be one-build out of sync)
RUN apt-get -qq update && \
    apt-get -qq install -y \
        wget python-catkin-tools && \
    rosdep update && \
    rosdep install -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO} --as-root=apt:false && \
    rm -rf /var/lib/apt/lists/*

# Replacing shell with bash for later docker build commands
# RUN mv /bin/sh /bin/sh-old && \
#    ln -s /bin/bash /bin/sh

# Build repo
WORKDIR $CATKIN_WS
ENV TERM xterm
ENV PYTHONIOENCODING UTF-8
RUN catkin config --extend /opt/ros/$ROS_DISTRO --install --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    # Status rate is limited so that just enough info is shown to keep Docker from timing out, but not too much
    # such that the Docker log gets too long (another form of timeout)
    catkin build --jobs 1 --limit-status-rate 0.001 --no-notify

RUN usermod -a -G sudo ${NRP_USER}

RUN chown ${NRP_USER}:${NRP_USER} /home/${NRP_USER}/.ros -R

COPY ./entrypoint_ur10.sh /usr/local/bin/docker-entrypoint.sh
RUN /bin/bash -c "chmod +x /usr/local/bin/docker-entrypoint.sh"

USER ${NRP_USER}
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD tail -f /dev/null
