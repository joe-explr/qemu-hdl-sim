
set proj_name riscv_test_sume

open_project ./${proj_name}.xpr
update_compile_order -fileset sources_1

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

close_project

