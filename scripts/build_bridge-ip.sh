#!/bin/bash

#runs from scripts folder
echo "start build_bridge-ip"

# execute source
source ./optbashrc.sh 20.1 18.1
source ./sourceme.sh


cd $COSIM_REPO_HOME/bridge-ip

cd nic_sim_bridge/
make

cd ..
cd uart_sim_1.0/
make

cd ..
cd QEMUPCIeBridge/
make

cd $COSIM_REPO_HOME/scripts

echo "finish build_bridge-ip"
