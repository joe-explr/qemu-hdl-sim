
set proj_name riscv_test_sume

open_project ./${proj_name}.xpr
update_compile_order -fileset sources_1

# Run

launch_runs synth_1 -jobs 16
wait_on_run synth_1

close_project

