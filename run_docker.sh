#!/usr/bin/env bash
# This script will build a Docker image with rosbridge in a catkin workspace,
# then run it with host networking and the sources mounted read-only.

cd "$(dirname "${BASH_SOURCE[0]}")"

CATKIN_DIR=/catkin_ws

docker build -t realsense .
docker run -it -d --net=host --privileged \
  --name rs_docker \
  -v "$(pwd)/realsense-ros/realsense2_description:${CATKIN_DIR}/src/realsense2_description:ro" \
  -v "$(pwd)/realsense-ros/realsense2_camera:${CATKIN_DIR}/src/realsense2_camera:ro" \
  -v "/dev:/dev" \
  -e DISPLAY=${DISPLAY} \
  -e ROS_MASTER_URI=${ROS_MASTER_URI}\
  -e ROS_IP=${ROS_IP} \
  realsense bash -c "roslaunch realsense2_camera rs_aligned_depth.launch"
