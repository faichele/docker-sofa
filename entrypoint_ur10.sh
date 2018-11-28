#!/bin/bash

echo "HOME: $HOME"
source $HOME/ws_moveit/install/setup.bash
export URSIM_IP=10.8.0.2
export ROS_IP=10.8.0.3
echo "ROS_ROOT: ${ROS_ROOT}"
echo "ROS_MASTER_URI: ${ROS_MASTER_URI}"

roslaunch ur_modern_driver ur10_bringup.launch robot_ip:=$URSIM_IP 
