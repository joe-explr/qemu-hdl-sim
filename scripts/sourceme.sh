# This should be run in COSIM_REPO_HOME/scripts
export COSIM_MAC=$((UID + 602500))
export COSIM_PORT=$((UID + 60250))
export COSIM_REPO_HOME="$PWD/.."
export NPU_COSIM_PORT=$((UID + 60250))
export MACADDR1="$(($UID % 100)):${UID:0:2}:60:25:00:20"
export MACADDR2="$(($UID % 100)):${UID:0:2}:60:25:00:21"
export BRIDGE="$USER-bridge"
