#!/bin/bash - 
#===============================================================================
#
#          FILE: netns-test.sh
# 
#         USAGE: ./netns-test.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Umair Ahmed Shah (), 
#  ORGANIZATION: 
#       CREATED: 06/08/2023 15:19
#      REVISION:  ---
#===============================================================================

# Function to log the steps
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") $1"
}

# Ping tests
log "Running network namespace tests..."

# Get the IP addresses of the namespaces
fc1_ip=$(ip netns exec fc1 ip -4 addr show dev veth-fc1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ar2_ip=$(ip netns exec ar2 ip -4 addr show dev veth-ar2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Ping from fc1 to ar2
log "Ping from fc1 ($fc1_ip) to ar2 ($ar2_ip):"
ip netns exec fc1 ping -c 3 "$ar2_ip"

# Ping from ar2 to fc1
log "Ping from ar2 ($ar2_ip) to fc1 ($fc1_ip):"
ip netns exec ar2 ping -c 3 "$fc1_ip"

log "Network namespace tests complete."


