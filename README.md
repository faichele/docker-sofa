===================================
Docker setup for SOFA and ROS.
===================================

This repository contains Dockerfiles and a docker-compose configuration for:
- A development installation for the SOFA framework
- A docker-ized installation of URSim, the offline programming simulator for robots from Universal Robotics (UR3, UR5, UR10)
- A docker-ized ROS Kinetic installation including Universal Robot ROS drivers and default MoveIt! installation

===================================
Requirements
===================================
- 20-30 GB disk space on a local hard drive.
- A NVidia GPU (older models should do).
- A checkout of the SOFA repository with the source code of the ROS connector plugin from: https://github.com/faichele/sofa-framework-private


==================================
Installing Docker and companions
==================================
The Dockerfiles have been tested with Docker CE (Community Edition) under Ubuntu 16.04.
Docker CE can be obtained from: https://docs.docker.com/install/linux/docker-ce/ubuntu/

To run GUI applications from a Docker container with hardware-accelerated OpenGL support (needed both by SOFA and ROS), nvidia-docker is required.
The two Docker images have only been tested with nvidia-docker version 1.0; version 2.0 should work as well.
Installation instructions for nvidia-docker can be found at: https://github.com/NVIDIA/nvidia-docker/wiki

Finally, for starting the two containers together, you need nvidia-docker-compose.
The tool and installation instructions can be found at: https://github.com/eywalker/nvidia-docker-compose

==================================
How to build the images
==================================

You need to download the installation archive for URSim, specifically version 3.6.0.30512, from:
https://www.universal-robots.com/download/
Select "CB series" -> "Software" -> "Offline Simulator" -> "Linux" -> "URSim 3.6.0".
Extract the downloaded TAR archive, which in turn contains another TAR archive named "ursim-3.6.0.30512.tar.gz". Copy this TAR archive to the directory where you checked out the docker-sofa repository.

First, you need to adapt some values in the file docker-compose.yml to your local setup:
- Change the value of all occurrences of NRP_USER. This is the name of the non-privileged user account that will be used in both Docker containers.
- 'networks' statements: The docker-compose setup for the two containers uses static IP address definitions. If for any reason you need to change these. please take care to pick consistent values for container IP adresses and subnet range.
- volumes definitions: I keep source and build directories for SOFA outside the container file systems. Adjust the corresponding volume definitions to the folders where you checked out your SOFA source and where you keep your SOFA build directories, respectively. Leave the "/tmp/.X11-unix" definitions unchanged. These are needed for X11 programs to work.
- devices definitions: In case you have multiple GPUs in your machine, pick the one that runs your X11 session. /dev/nvidia0 should be fine in most cases.
- The NVidia driver "volume" (at the end of the docker-compose file). The name of this volume will likely be different in your case, depending on the version of your NVidia graphics card driver.
To (re-)create a nvidia driver volume, proceed as explained under "Quickstart" for Ubuntu 16.04 here: https://github.com/NVIDIA/nvidia-docker/wiki/Driver-containers-(EXPERIMENTAL)
Specifically:

docker run --rm --runtime=nvidia nvidia/cuda:9.2-base nvidia-smi

should create a suitable driver volume for you.
Locate the volume name you need to put at the end of the docker-compose file in the output of:

docker volume ls

The volume should use the "nvidia-docker" driver.

In the directory where you cloned the repository to, use the command:
docker-compose build

The initial build process for the containers will take some time, since both ROS and a part of the SOFA dependencies are built from source.

==================================
How to start the containers
==================================

First, you need to allow X11 protocol connections to your desktop session (otherwise, programs with a GUI won't start from within a Docker container). 
xhost +local:

Then, you can start the containers with:
nvidia-docker-compose -f docker-compose.yml up -d

To show the container status:
nvidia-docker-compose ps

To run an interactive bash shell in one of the containers:
nvidia-docker-compose exec -u <user name> ros-moveit /bin/bash

==================================
Questions and Issues
==================================
Please do not hesitate to use the bug tracker at https://github.com/faichele/sofa-framework-private or https://github.com/faichele/docker-sofa.
You can also reach me via e-mail at: aichele<at>zykl.io (replace the <at> with @).
