#!/bin/bash
# runs from the scripts folder
echo "start make-bridge"
source sourceme.sh

echo "clean bridge"
sudo ip link delete tap$USER
sudo brctl delbr $BRIDGE

# make the bridge
echo "build bridge"
sudo brctl addbr $BRIDGE
sudo ip tuntap add dev tap$USER mode tap
sudo ip link set dev tap$USER up
sudo brctl addif $BRIDGE tap$USER

echo "allow $BRIDGE" | sudo tee -a /usr/local/etc/qemu/bridge.conf
echo "created bridge $BRIDGE"
# sudo chmod 666 /dev/net/tun
echo "finish make-bridge"
