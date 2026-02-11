
set device "xc7vx690t_0"
set bitstream   "./riscv_test_sume.runs/impl_1/top_syn.bit"   
#set bitstream   "./top_syn_elf.bit"   
set probes ""
set fullprobes ""

open_hw
connect_hw_server -url triangle:3121
open_hw_target
current_hw_device [get_hw_devices ${device}]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${device}] 0]
set_property PROBES.FILE {} [get_hw_devices ${device}]
set_property FULL_PROBES.FILE {} [get_hw_devices ${device}]
set_property PROGRAM.FILE ${bitstream} [get_hw_devices ${device}]

program_hw_devices [get_hw_devices ${device}]
refresh_hw_device [lindex [get_hw_devices] 0]
quit

