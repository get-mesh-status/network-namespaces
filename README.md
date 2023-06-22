
### Network namespaces in Linux 
![network namespaces ](https://github.com/get-mesh-status/network-namespaces/blob/master/netw-ns-1.drawio.png)
### create network namespaces 
```sh
sudo ip netns add fc1 
  
sudo ip netns add ar2 
```
## list network namespaces  
```  
$ip netns list  
ar2 (id: 1)  
fc1 (id: 0)
```
## To create both veth pairs
```  
sudo ip link add veth-fc1 type veth peer name bridge-fc1-veth | tee -a $LOGFILE  
  
sudo ip link add veth-ar2 type veth peer name bridge-ar2-veth | tee -a $LOGFILE  
 ``` 
### now when we look at the devices , we see the veth pairs on the host  
```
$ip link list | grep veth  
10: bridge-fc1-veth@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master ground-bridge state UP mode DEFAULT group default qlen  
1000  
12: bridge-ar2-veth@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master ground-bridge state UP mode DEFAULT group default qlen  
1000
```  
  
  
### attach the veth cables to the respective namespaces  
```
sudo ip link set veth-fc1 netns fc1 | tee -a $LOGFILE  
  
sudo ip link set veth-ar2 netns ar2 | tee -a $LOGFILE  
```  
### we can see now the veth-fc1 and veth-ar2 won't show up in host namespace.  
  
### To see the ends of the virtual link (Cable) we can run ip link command within namespaces  
  ```
sudo ip netns exec fc1 \  
ip link show | tee -a $LOGFILE  
sudo ip netns exec ar2 \  
ip link show | tee -a $LOGFILE  
  ```
  
### Now we can assign IP address to the each namespace  
```  
sudo ip netns exec fc1 \  
ip address add 192.168.0.40/24 dev veth-fc1 | tee -a $LOGFILE  
sudo ip netns exec fc1 \  
ip link set veth-fc1 up | tee -a $LOGFILE  
  
  
sudo ip netns exec ar2 \  
ip address add 192.168.0.80/24 dev veth-ar2 | tee -a $LOGFILE  
  
sudo ip netns exec ar2 \  
ip link set veth-ar2 up | tee -a $LOGFILE  
```
  
### Verify the ip addresses are assigned  
  ```
  $sudo ip netns exec fc1 ip addr show veth-fc1  
11: veth-fc1@if10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000  
link/ether 76:cc:2c:fc:a8:2e brd ff:ff:ff:ff:ff:ff link-netnsid 0  
inet 192.168.0.40/24 scope global veth-fc1  
valid_lft forever preferred_lft forever  
inet6 fe80::74cc:2cff:fefc:a82e/64 scope link  
valid_lft forever preferred_lft forever
```

```sh 
$brctl show ground-bridge  
bridge name bridge id 		STP enabled 	interfaces  
ground-bridge 8000.4ebe86c21fe2 no 		bridge-ar2-veth  
										bridge-fc1-veth
```

### Now verify the the two sites fc1 and ar2 can ping each other  
  
```sh
$sudo ip netns exec ar2 ping -c2 192.168.0.40  
PING 192.168.0.40 (192.168.0.40) 56(84) bytes of data.  
64 bytes from 192.168.0.40: icmp_seq=1 ttl=64 time=0.028 ms  
64 bytes from 192.168.0.40: icmp_seq=2 ttl=64 time=0.053 ms  
  
--- 192.168.0.40 ping statistics ---  
2 packets transmitted, 2 received, 0% packet loss, time 1016ms  
rtt min/avg/max/mdev = 0.028/0.040/0.053/0.012 ms
```
* Running tcpdump on the `bridge` interface while `ping` is in progress
```sh
$sudo tcpdump -i ground-bridge -n -vv  
dropped privs to tcpdump  
tcpdump: listening on ground-bridge, link-type EN10MB (Ethernet), snapshot length 262144 bytes  
20:43:36.984541 IP (tos 0x0, ttl 64, id 31963, offset 0, flags [DF], proto ICMP (1), length 84)  
192.168.0.40 > 192.168.0.80: ICMP echo request, id 8582, seq 1, length 64  
20:43:36.984560 IP (tos 0x0, ttl 64, id 22487, offset 0, flags [none], proto ICMP (1), length 84)  
192.168.0.80 > 192.168.0.40: ICMP echo reply, id 8582, seq 1, length 64  
20:43:38.028401 IP (tos 0x0, ttl 64, id 32690, offset 0, flags [DF], proto ICMP (1), length 84)  
192.168.0.40 > 192.168.0.80: ICMP echo request, id 8582, seq 2, length 64  
20:43:38.028432 IP (tos 0x0, ttl 64, id 22705, offset 0, flags [none], proto ICMP (1), length 84)  
192.168.0.80 > 192.168.0.40: ICMP echo reply, id 8582, seq 2, length 64
```

#### Cleaning up 
```sh 

$sudo ip link set ground-bridge down  
$sudo brctl delbr ground-bridge  
$sudo ip link delete bridge-ar2-veth  
$sudo ip link delete bridge-fc1-veth  
```

### Inside the container 
```
podman build -t my-container-image . 
```
To use it, follow these steps:

Start the container: podman run -it --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=NET_RAW my-container-image
Inside the container, navigate to the script directory: cd /root
Run the network namespaces setup script: ./netns-setup.sh
Run the network namespaces test script: ./netns-test.sh
If the test is successful, proceed with other operations. If not, investigate the issue and make necessary adjustments.
Finally, tear down the network namespaces using ./netns-teardown.sh.
By running the netns-test.sh script after setting up the network namespaces, you can verify the functionality of the namespaces and the connectivity between the fc1 and ar2 namespaces.

