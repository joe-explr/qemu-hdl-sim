# Vivado batch: reset and run simulation (sim_1)
set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]

set proj_name "vcu128_base"
set proj_path [file join $repo_dir platform $proj_name "${proj_name}.xpr"]
set sim_mode "behavioral"
set sim_type "functional"

if { [info exists ::VIVADO_FLOW_PROJECT] && $::VIVADO_FLOW_PROJECT ne "" } {
  set proj_path $::VIVADO_FLOW_PROJECT
}
if { [info exists ::VIVADO_FLOW_SIM_MODE] } {
  set sim_mode $::VIVADO_FLOW_SIM_MODE
}
if { [info exists ::VIVADO_FLOW_SIM_TYPE] } {
  set sim_type $::VIVADO_FLOW_SIM_TYPE
}

proc print_help {} {
  puts "Usage: run_sim.tcl -tclargs [--project <path>] [--sim-mode <behavioral|post-synthesis|post-implementation>] [--sim-type <functional|timing> (post-* only)]"
}

if { (![info exists ::VIVADO_FLOW_FROM_ALL] || !$::VIVADO_FLOW_FROM_ALL) && $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set opt [string trim [lindex $::argv $i]]
    switch -- $opt {
      "--project" { incr i; set proj_path [lindex $::argv $i] }
      "--sim-mode" { incr i; set sim_mode [lindex $::argv $i] }
      "--sim-type" { incr i; set sim_type [lindex $::argv $i] }
      "--help" { print_help; exit 0 }
      default {
        if { [regexp {^-} $opt] } {
          puts "ERROR: Unknown option '$opt'"
          print_help
          exit 1
        }
      }
    }
  }
}

if { ![file exists $proj_path] } {
  puts "ERROR: Project file not found: $proj_path"
  exit 1
}

set proj_open 0
if { ![catch {current_project}] } {
  set proj_open 1
}
if { !$proj_open } {
  open_project $proj_path
}

if { [get_filesets -quiet sim_1] eq "" } {
  puts "WARNING: sim_1 fileset not found; skipping simulation"
  exit 0
}

if { [catch {reset_simulation} reset_err] } {
  puts "INFO: reset_simulation not available or failed: $reset_err"
}

puts "INFO: Launching simulation (sim_1, $sim_mode)"
if { $sim_mode eq "behavioral" } {
  launch_simulation -simset sim_1 -mode $sim_mode
} else {
  puts "INFO: Simulation type: $sim_type"
  launch_simulation -simset sim_1 -mode $sim_mode -type $sim_type
}

puts "INFO: Simulation complete"
