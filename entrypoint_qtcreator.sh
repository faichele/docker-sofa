#!/bin/bash

USER=fabian
source /opt/ros/kinetic/setup.bash
echo "ROS_ROOT: ${ROS_ROOT}"
echo "ROS_MASTER_URI: ${ROS_MASTER_URI}"
sudo chown $USER.$USER /home/$USER -R
roscore &
qtcreator
