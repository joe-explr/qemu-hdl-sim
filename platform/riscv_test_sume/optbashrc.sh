#!/bin/bash


export LM_LICENSE_FILE=4999@license.ece.stonybrook.edu:4999@license0.ece.stonybrook.edu

# for Xilinx tools
export XILINXD_LICENSE_FILE=4999@license.ece.stonybrook.edu:2101@cyclops.ece.sunysb.edu:4999@license.ece.sunysb.edu
if [ `getconf LONG_BIT` = "64" ]
then
    source /compas/opt/Xilinx/Vivado/20$1/settings64.sh
#   source /compas/opt/Xilinx/Vivado/2018.1/settings64.sh
#   source /compas/opt/Xilinx/14.7/ISE_DS/settings64.sh
else
    source /compas/opt/Xilinx/Vivado/20$1/settings32.sh
#   source /compas/opt/Xilinx/Vivado/2018.1/settings32.sh
#   source /compas/opt/Xilinx/14.7/ISE_DS/settings32.sh
fi


# for Matlab
export PATH=/compas/opt/MATLAB/R2012b/bin:/usr/lib/lightdm/lightdm:$PATH

# for Synopsys tools
#export LM_LICENSE_FILE=${LM_LICENSE_FILE}:4999@license.ece.stonybrook.edu
#export SPECMAN_LICENSE_FILE=${SPECMAN_LICENSE_FILE}:4999@license.ece.stonybrook.edu
export SPECMAN_LICENSE_FILE=4999@license.ece.stonybrook.edu

# for Synplify
export PATH=/compas/opt/synopsys/I-2014.03/bin:${PATH}
#export PATH=/compas/opt/synopsys/L-2016.03/bin:${PATH}
# for Synplify in batch mode
export SYNPLIFYPRO_LICENSE_TYPE=synplifypremierdp

# for VCS
export VCS_ARCH_OVERRIDE=linux
#VCS_HOME=/compas/opt/synopsys/J-2014.12-SP3-8
#SPECMAN_HOME=/compas/opt/synopsys/J-2014.12-SP3-8
VCS_HOME=/compas/opt/synopsys/vcs-mx/M-2017.03-SP2-2
SPECMAN_HOME=/compas/opt/synopsys/vcs-mx/M-2017.03-SP2-2
export VCS_HOME SPECMAN_HOME
. $VCS_HOME/bin/sn_env.sh

# for Verdi
export NOVAS_HOME=/compas/opt/synopsys/verdi/Verdi3-I-201403-SP2
export PATH=${NOVAS_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${NOVAS_HOME}/share/PLI/lib/LINUX64:${LD_LIBRARY_PATH}


# for Bluespec
export BLUESPECDIR=/compas/opt/Bluespec-2014.05.C/lib
export BLUESPEC_HOME=/compas/opt/Bluespec-2014.05.C
export PATH=$BLUESPECDIR/../bin:$PATH
export LM_LICENSE_FILE=${LM_LICENSE_FILE}:27005@breweryhill

# for ModelSim
export PATH=/compas/opt/modelsim10/modeltech/bin:$PATH
export LM_LICENSE_FILE=${LM_LICENSE_FILE}:1717@license.ece.stonybrook.edu


# for Altera
if [ `getconf LONG_BIT` = "64" ]
then
    export QUARTUS_64BIT="1"
    #export ALTERAROOT="/compas/opt/altera/16.1"
    export ALTERAROOT="/compas/opt/altera/$2"
    export PATH=${ALTERAROOT}/quartus/bin:$PATH
    export ALTERAOCLSDKROOT="${ALTERAROOT}/hld"
    export AOCL_BOARD_PACKAGE_ROOT="$ALTERAOCLSDKROOT/board/terasic/de5net"
    export QSYS_ROOTDIR="${ALTERAROOT}/quartus/sopc_builder/bin"
    export LM_LICENSE_FILE=${LM_LICENSE_FILE}:5500@license.ece.stonybrook.edu:2101@license0.ece.stonybrook.edu
    source $ALTERAOCLSDKROOT/init_opencl.sh
else
    echo "Altera Quartus II only supports 64-bit Linux."
fi

