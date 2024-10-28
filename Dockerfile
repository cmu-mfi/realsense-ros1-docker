ARG DOCKER_ROS_DISTRO=noetic
FROM ros:${DOCKER_ROS_DISTRO}

# Booststrap workspace.
ENV CATKIN_DIR=/catkin_ws
RUN . /opt/ros/$ROS_DISTRO/setup.sh \
 && mkdir -p $CATKIN_DIR/src \
 && cd $CATKIN_DIR/src \
 && catkin_init_workspace
WORKDIR $CATKIN_DIR


# Install librealsense
RUN apt-get update
RUN apt-get install -y curl vim tmux
RUN mkdir -p /etc/apt/keyrings
RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | tee /etc/apt/keyrings/librealsense.pgp
RUN apt-get install apt-transport-https
RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | tee /etc/apt/sources.list.d/librealsense.list
RUN apt-get update
RUN apt-get install librealsense2-dkms -y
RUN apt-get install librealsense2-utils -y 
RUN apt-get install librealsense2-dev -y 
RUN apt-get install librealsense2-dbg -y

# Install dependencies first.
COPY realsense-ros/realsense2_camera/package.xml $CATKIN_DIR/src/realsense2_camera/
COPY realsense-ros/realsense2_description/package.xml $CATKIN_DIR/src/realsense2_description/
RUN . /opt/ros/$ROS_DISTRO/setup.sh \
 && apt-get update \
 && rosdep update \
 && rosdep install \
    --from-paths src \
    --ignore-src \
    --rosdistro $ROS_DISTRO \
    -y \
 && rm -rf /var/lib/apt/lists/*

# Build rosbridge packages.
COPY realsense-ros/realsense2_camera $CATKIN_DIR/src/realsense2_camera
COPY realsense-ros/realsense2_description $CATKIN_DIR/src/realsense2_description
RUN . /opt/ros/$ROS_DISTRO/setup.sh \
 && catkin_make clean \
 && catkin_make -DCATKIN_ENABLE_TESTING=False -DCMAKE_BUILD_TYPE=Release



# We want the development workspace active all the time.
RUN echo "#!/bin/bash\n\
set -e\n\
source \"${CATKIN_DIR}/devel/setup.bash\"\n\
exec \"\$@\"" > /startup.sh \
 && chmod a+x /startup.sh \
 && echo "source ${CATKIN_DIR}/devel/setup.bash" >> /root/.bashrc
ENTRYPOINT ["/startup.sh"]
CMD ["bash"]
