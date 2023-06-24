#!/bin/bash

# Get the current timestamp
timestamp=$(date +"%Y-%m-%d-%H%M%S%3N")

# Get the script name without the path
script_name="netns-test"

# Define the logfile name with script name and timestamp
logfile_name="${script_name}-${timestamp}.log"
# Function to log the steps
log() {
  timestamp=$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")
  echo "$timestamp $1"
  echo "$timestamp $1" >> "$logfile_name"
}


# Function to cleanup and exit the script
cleanup() {
  # Teardown network namespaces
  sudo ./netns-teardown.sh
  log "Network namespaces teardown complete."

  # Exit the script
  exit $1
}

# Set the container image name
container_image="my-container-image"

# Start the container with network namespaces setup
log "Starting container..."
container_id=$(podman run -d -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_RAW --userns=keep-id "$container_image")
if podman ps --quiet --filter "id=$container_id" >/dev/null; then
    echo "Container $container_id is running."
else
    echo "Failed to start container. Exiting..."
    cleanup 1
fi

log "Container started with ID: $container_id"

# Setup network namespaces
log "Setting up network namespaces..."
sudo ./netns-setup.sh
log "Network namespaces setup complete."

# Ping tests
log "Running ping tests..."

# Get the IP addresses of the namespaces
fc1_ip=$(sudo ip netns exec fc1 ip -4 addr show dev veth-fc1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ar2_ip=$(sudo ip netns exec ar2 ip -4 addr show dev veth-ar2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Ping from fc1 to ar2
log "Ping from fc1 ($fc1_ip) to ar2 ($ar2_ip):"
sudo ip netns exec fc1 ping -c 3 "$ar2_ip"

# Ping from ar2 to fc1
log "Ping from ar2 ($ar2_ip) to fc1 ($fc1_ip):"
sudo ip netns exec ar2 ping -c 3 "$fc1_ip"

log "Ping tests complete."

export LIBPOD_LOG_LEVEL=debug


# Stop and remove the container
log "Stopping and removing the container..."
podman --log-level debug stop --timeout 15 "$container_id" && podman --log-level debug rm "$container_id" 2>&1 | tee -a script.log

log "Container stopped and removed."
unset LIBPOD_LOG_LEVEL
# Exit the script
cleanup 0

