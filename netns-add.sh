#!/bin/bash 


TIMESTAMP=$(date  "+%Y-%m-%d %H-%M-%S")
MyDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SCRIPTNAME=$(basename $0)
LOGFILE="${MyDir}/${SCRIPTNAME%.*}-$(date +'%Y-%m-%d').log"

printf "Adding network namespaces ..  $(date +"%Y-%m-%d %H:%M:%S,%3N")"  >> $LOGFILE 2>/dev/null 
printf  "\n$(date +'%H:%M:%S:%3N')" | tee -a "${LOGFILE}" 2>&1

printf "\n ---------------------------------------------\n"  | tee -a "${LOGFILE}" 2>&1

sudo ip netns add fc1  2>/dev/null

sudo ip netns add ar2 2>/dev/null

## list network namespaces

ip netns list |  tee -a $LOGFILE 
## To create both veth pairs, use the following 

sudo ip link add veth-fc1  type veth peer name bridge-fc1-veth |  tee -a $LOGFILE 

sudo ip link add veth-ar2 type veth peer name bridge-ar2-veth |   tee -a $LOGFILE 

### now when we look at the devices , we see the veth pairs on the host 

ip link list  |   tee -a $LOGFILE 

### attach the veth cables to the respective namespaces
sudo ip link set veth-fc1 netns fc1 |   tee -a $LOGFILE 

sudo ip link set veth-ar2 netns ar2 |   tee -a $LOGFILE 

## we can see now the veth-fc1 and veth-ar2 won't show up in host namespace. 

## to see the ends of the virtual link (Cable) we can run ip link command within namespaces

sudo ip netns exec fc1  \
ip link show  |   tee -a $LOGFILE 
sudo ip netns exec ar2  \ 
ip link show  |   tee -a $LOGFILE 

### Now we can assign IP address to the each namespace

sudo ip netns exec fc1 \
ip address add 192.168.0.40/24 dev veth-fc1 |   tee -a $LOGFILE 
sudo ip netns exec fc1 \
ip link set veth-fc1 up   |   tee -a $LOGFILE 


sudo ip netns exec ar2 \
ip address add  192.168.0.80/24 dev veth-ar2 |   tee -a $LOGFILE 

sudo ip netns exec ar2 \
ip link set veth-ar2 up |   tee -a $LOGFILE 

### Verify the ip addresses are assigned 

sudo ip netns exec fc1 \
ip addr show |   tee -a $LOGFILE 

sudo ip netns exec ar2 \
ip addr show |   tee -a $LOGFILE 


### Bridging the namespaces

sudo ip link add name ground-bridge  type bridge |   tee -a $LOGFILE 
## bring up the bridge interface 
sudo ip link set ground-bridge up |   tee -a $LOGFILE 

### Now connect the bridge side of veth cable to the bridge 

sudo ip link set bridge-fc1-veth up |   tee -a $LOGFILE 

sudo ip link set bridge-ar2-veth up |   tee -a $LOGFILE 

### Now add the the above *-veth interface to the bridge we created earlier 

sudo ip link set bridge-fc1-veth master ground-bridge |   tee -a $LOGFILE 

sudo ip link set bridge-ar2-veth master ground-bridge |   tee -a $LOGFILE 
### To verify 
brctl show ground-bridge |   tee -a $LOGFILE 

### Now verify the the two sites fc1 and ar2 can ping each other 

sudo ip netns exec ar2 \
ping  -c3 192.168.0.40  |   tee -a $LOGFILE 



