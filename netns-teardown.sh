#!/bin/bash

set -e  # Exit immediately if any command fails

# Delete the network namespaces
ip netns delete fc1 || true  # Ignore failure if namespace doesn't exist
ip netns delete ar2 || true  # Ignore failure if namespace doesn't exist

# Delete the bridge
if ip link show ground-bridge &> /dev/null; then
    ip link set ground-bridge down
    brctl delbr ground-bridge
fi

