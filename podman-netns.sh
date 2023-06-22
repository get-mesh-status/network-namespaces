#===============================================================================
#
#          FILE: automate-networking.sh
# 
#         USAGE: ./automate-networking.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Umair Ahmed Shah (), 
#  ORGANIZATION: 
#       CREATED: 06/08/2023 15:11
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#!/bin/bash

# Function to log the steps
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") $1"
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
container_id=$(sudo systemd-run --scope --slice=netns-slice podman run -d -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_RAW "$container_image")

# Check if the container started successfully
if [ -z "$container_id" ]; then
  log "Failed to start container. Exiting..."
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

# Teardown network namespaces
log "Tearing down network namespaces..."
sudo ./netns-teardown.sh
log "Network namespaces teardown complete."

# Stop and remove the container
log "Stopping and removing the container..."
sudo podman stop "$container_id" && sudo podman rm "$container_id"
log "Container stopped and removed."

# Exit the script
cleanup 0


