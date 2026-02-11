#!/bin/bash
source sourceme.sh

cd $COSIM_REPO_HOME
mkdir qemu_logs
mkdir qemu_logs/accel
mkdir qemu_logs/orig

# run patched qemu
# NOTE! CURRENTLY, MALKA DOESN'T HAVE KVM ENABLED SO REMOVE THE KVM FLAG!
cd $COSIM_REPO_HOME/qemu-10.1.3
./build/qemu-system-x86_64 -L ./pc-bios -m 4G -hda /var/services/homes/jbantony/qemu-hdl-cosim_orig/images/npu_ubuntu_64_1804.qcow2 -device accelerator-pcie,netdev=net0,chardev=char0 -netdev tap,id=net0,br=$BRIDGE,helper=/compas/projects/qemu-hdl-cosim/bridge-helper/ubuntu_18.04/qemu-bridge-helper_orig -chardev vc,id=char0 -snapshot -boot d -enable-kvm -display vnc=:8 -D ../qemu_logs/accel/qemu_output_patched.log -d in_asm,out_asm,op,op_opt,op_ind,int,exec,cpu,mmu,unimp,guest_errors > ../qemu_logs/accel/qemu_error_logs_patched.log 2>&1 &

# run unpatched qemu
cd $COSIM_REPO_HOME/qemu-10.1.3_orig
# ./build/qemu-system-x86_64 -L ./pc-bios -m 8G -hda /var/services/homes/jbantony/qemu-hdl-cosim_orig/images/npu_ubuntu_64_1804.qcow2 -netdev tap,id=net0,br=$BRIDGE,helper=/compas/projects/qemu-hdl-cosim/bridge-helper/ubuntu_18.04/qemu-bridge-helper_orig -chardev vc,id=char0 -snapshot -boot d -enable-kvm -display vnc=:9 -D ../qemu_logs/orig/qemu_output.log -d in_asm,out_asm,op,op_opt,op_ind,int,exec,cpu,mmu,unimp,guest_errors > ../qemu_logs/orig/qemu_logs.log 2>&1

./build/qemu-system-x86_64 -L ./pc-bios -m 8G -enable-kvm -cpu host -smp cores=6 -hda /var/services/homes/jbantony/qemu-hdl-cosim_orig/images/npu_ubuntu_64_1804_old.qcow2 -device e1000,mac=$MACADDR1,netdev=net1 -netdev tap,id=net1,br=$BRIDGE,helper=/compas/projects/qemu-hdl-cosim/bridge-helper/ubuntu_18.04/qemu-bridge-helper_orig -display vnc=:9 -D ../qemu_logs/orig/qemu_output.log -d in_asm,out_asm,op,op_opt,op_ind,int,exec,cpu,mmu,unimp,guest_errors > ../qemu_logs/orig/qemu_logs.log 2>&1 &

# The Dummy VM will be available in the port 5909 (vnc=:9 )of the host machine, accessible with a VNC viewer.
# The FPGA VM will be available in the port 5908 (vnc=:8 )of the host machine, accessible with a VNC viewer.