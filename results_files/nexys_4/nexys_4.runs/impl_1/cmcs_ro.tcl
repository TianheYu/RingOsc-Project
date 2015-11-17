proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param gui.test TreeTableDev
  debug::add_scope template.lib 1
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.cache/wt [current_project]
  set_property parent.project_path C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.xpr [current_project]
  set_property ip_repo_paths c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.cache/ip [current_project]
  set_property ip_output_repo c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.cache/ip [current_project]
  add_files -quiet C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.runs/synth_1/cmcs_ro.dcp
  add_files -quiet C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.runs/xadc_wiz_0_synth_1/xadc_wiz_0.dcp
  set_property netlist_only true [get_files C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.runs/xadc_wiz_0_synth_1/xadc_wiz_0.dcp]
  read_xdc -mode out_of_context -ref xadc_wiz_0 -cells inst c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.srcs/sources_1/ip/xadc_wiz_0/xadc_wiz_0_ooc.xdc
  set_property processing_order EARLY [get_files c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.srcs/sources_1/ip/xadc_wiz_0/xadc_wiz_0_ooc.xdc]
  read_xdc -ref xadc_wiz_0 -cells inst c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.srcs/sources_1/ip/xadc_wiz_0/xadc_wiz_0.xdc
  set_property processing_order EARLY [get_files c:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.srcs/sources_1/ip/xadc_wiz_0/xadc_wiz_0.xdc]
  read_xdc C:/Users/Tianhe/Desktop/heat_files/results_files/repo_src/constrs_1/cmcs_r1.xdc
  read_xdc -ref ring_osc C:/Users/Tianhe/Desktop/heat_files/results_files/repo_src/constrs_1/lock_pin.xdc
  read_xdc -ref ro_array C:/Users/Tianhe/Desktop/heat_files/results_files/repo_src/9626_constrain_and_source_files/route_with_the_other_slice9626.xdc
  link_design -top cmcs_ro -part xc7a100tcsg324-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force cmcs_ro_opt.dcp
  catch {report_drc -file cmcs_ro_drc_opted.rpt}
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  place_design 
  write_checkpoint -force cmcs_ro_placed.dcp
  catch { report_io -file cmcs_ro_io_placed.rpt }
  catch { report_clock_utilization -file cmcs_ro_clock_utilization_placed.rpt }
  catch { report_utilization -file cmcs_ro_utilization_placed.rpt -pb cmcs_ro_utilization_placed.pb }
  catch { report_control_sets -verbose -file cmcs_ro_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force cmcs_ro_routed.dcp
  catch { report_drc -file cmcs_ro_drc_routed.rpt -pb cmcs_ro_drc_routed.pb }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file cmcs_ro_timing_summary_routed.rpt -rpx cmcs_ro_timing_summary_routed.rpx }
  catch { report_power -file cmcs_ro_power_routed.rpt -pb cmcs_ro_power_summary_routed.pb }
  catch { report_route_status -file cmcs_ro_route_status.rpt -pb cmcs_ro_route_status.pb }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  set src_rc [catch { 
    puts "source C:/Users/Tianhe/Desktop/heat_files/results_files/loop_warn.tcl"
    source C:/Users/Tianhe/Desktop/heat_files/results_files/loop_warn.tcl
  } _RESULT] 
  if {$src_rc} { 
    send_msg_id runtcl-1 error "$_RESULT"
    send_msg_id runtcl-2 error "sourcing script C:/Users/Tianhe/Desktop/heat_files/results_files/loop_warn.tcl failed"
    return -code error
  }
  write_bitstream -force cmcs_ro.bit 
  if { [file exists C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.runs/synth_1/cmcs_ro.hwdef] } {
    catch { write_sysdef -hwdef C:/Users/Tianhe/Desktop/heat_files/results_files/nexys_4/nexys_4.runs/synth_1/cmcs_ro.hwdef -bitfile cmcs_ro.bit -meminfo cmcs_ro.mmi -file cmcs_ro.sysdef }
  }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

