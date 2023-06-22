#!/bin/bash -

set -o nounset

# Create network namespaces
ip netns add fc1
ip netns add ar2

# Create veth pairs
ip link add veth-fc1 type veth peer name bridge-fc1-veth
ip link add veth-ar2 type veth peer name bridge-ar2-veth

# Attach veth cables to namespaces
ip link set veth-fc1 netns fc1
ip link set veth-ar2 netns ar2

# Assign IP addresses
ip netns exec fc1 ip address add 192.168.0.40/24 dev veth-fc1
ip netns exec fc1 ip link set veth-fc1 up
ip netns exec ar2 ip address add 192.168.0.80/24 dev veth-ar2
ip netns exec ar2 ip link set veth-ar2 up

# Create bridge interface
ip link add name ground-bridge type bridge
ip link set ground-bridge up

# Connect veth cables to the bridge
ip link set bridge-fc1-veth up
ip link set bridge-ar2-veth up
ip link set bridge-fc1-veth master ground-bridge
ip link set bridge-ar2-veth master ground-bridge

# Display network namespace information
ip netns list
ip link list
ip addr show
brctl show ground-bridge

