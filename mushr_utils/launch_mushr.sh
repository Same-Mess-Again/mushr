#!/bin/bash

# MuSHR tmux launch script
# Sets up multiple panes to run different ROS launch files in a Docker container

SESSION_NAME="mushr"
MUSHR_INSTALL_PATH="/home/airavata/catkin_ws/src/mushr/mushr_utils/install"
MUSHR_COMPOSE_FILE="docker-compose-robot.yml"
CONTAINER_NAME="mushr_noetic"

# Set up environment variables
export MUSHR_INSTALL_PATH="/home/airavata/catkin_ws/src/mushr/mushr_utils/install"
export MUSHR_REAL_ROBOT=1
export MUSHR_WS_PATH=/home/airavata
export MUSHR_COMPOSE_FILE="docker-compose-robot.yml"
export MUSHR_OS_TYPE="aarch64"

# Cleanup function to stop container on exit
cleanup() {
  echo "Stopping Docker container..."
  docker-compose -f $MUSHR_INSTALL_PATH/$MUSHR_COMPOSE_FILE down 2>/dev/null || true
}
trap cleanup EXIT

# Kill existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null || true

# Start the Docker container in the background
echo "Starting Docker container..."
docker-compose -f $MUSHR_INSTALL_PATH/$MUSHR_COMPOSE_FILE run -d -p 9090:9090 $CONTAINER_NAME sleep infinity
sleep 5  # Wait for container to start

# Get the running container ID
CONTAINER_ID=$(docker ps --filter "label=com.docker.compose.service=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
if [ -z "$CONTAINER_ID" ]; then
  echo "Failed to start Docker container"
  exit 1
fi
echo "Container started: $CONTAINER_ID"

# Create a new tmux session with mouse support enabled
tmux new-session -d -s $SESSION_NAME -x 200 -y 50

# Enable mouse support
tmux set-option -t $SESSION_NAME mouse on

# Pane 0: Launch teleop
tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && roslaunch mushr_base teleop.launch'" Enter
sleep 10

# Create pane 1: map_server
tmux split-window -t $SESSION_NAME -h
tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && roslaunch mushr_base map_server.launch'" Enter


# Create pane 2: mushr_pf
tmux split-window -t $SESSION_NAME -v
tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && roslaunch mushr_pf real.launch'" Enter

# Create pane 3: mushr_rhc
tmux split-window -t $SESSION_NAME -v
tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && roslaunch mushr_rhc real.launch'" Enter


# Create pane 4: mushr_gp
tmux split-window -t $SESSION_NAME -v
tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && roslaunch mushr_gp real.launch'" Enter


# # Create pane 5: teleop_twist_keyboard
# tmux split-window -t $SESSION_NAME -v
# tmux send-keys -t $SESSION_NAME "docker exec -it $CONTAINER_ID bash -c 'source /root/catkin_ws/devel/setup.bash && rosrun teleop_twist_keyboard teleop_twist_keyboard.py cmd_vel:=/car/foxglove/teleop'" Enter

# Attach to the session
tmux attach-session -t $SESSION_NAME
