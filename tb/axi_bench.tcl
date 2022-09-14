## Utility
source ../util.tcl

## Device setting (KCU105)
set p_device "xczu28dr-ffvg1517-2-e"

set project_name "axi_bench"

create_project -force $project_name ./${project_name} -part $p_device
set_property  ip_repo_paths  {"../ip_repo" "../hls/proj_rewind"} [current_project]

## create board design
create_bd_design "system"

### DDC_DAQ2
create_bd_cell -type ip -vlnv [latest_ip axi_rewind] axi_rewind

### AXI VIP
create_bd_cell -type ip -vlnv [latest_ip axi_vip] axi_vip
set_property CONFIG.INTERFACE_MODE {MASTER} [get_bd_cells axi_vip]

### Interconnect
create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect
set_property CONFIG.NUM_MI {4} [get_bd_cells axi_interconnect]


## Connection
### Port definition
#### Clock and reset
create_bd_port -dir I -type clk axi_clk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports axi_clk]
create_bd_port -dir I -type clk s_axis_aclk
set_property CONFIG.FREQ_HZ 256000000 [get_bd_ports s_axis_aclk]

create_bd_port -dir I -type rst axi_aresetn
create_bd_port -dir I -type rst s_axis_aresetn

#### Data
# Input
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axis_data_in
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {1} \
                         CONFIG.HAS_TKEEP {1} \
                         CONFIG.HAS_TSTRB {1} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.TDATA_NUM_BYTES {12}] [get_bd_intf_ports axis_data_in]
connect_bd_intf_net [get_bd_intf_ports axis_data_in] [get_bd_intf_pins axi_rewind/axis_data_in]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axis_phase_out
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {0} \
                         CONFIG.HAS_TKEEP {0} \
                         CONFIG.HAS_TSTRB {0} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.TDATA_NUM_BYTES {8}] [get_bd_intf_ports axis_phase_out]
connect_bd_intf_net [get_bd_intf_ports axis_phase_out] [get_bd_intf_pins axi_rewind/axis_phase_out]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axis_data_out
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {1} \
                         CONFIG.HAS_TKEEP {1} \
                         CONFIG.HAS_TSTRB {1} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.HAS_TUSER {1} \
                         CONFIG.TDATA_NUM_BYTES {12} \
                         CONFIG.TUSER_WIDTH {1}] [get_bd_intf_ports axis_data_out]
connect_bd_intf_net [get_bd_intf_ports axis_data_out] [get_bd_intf_pins axi_rewind/axis_data_out]


### AXI intf
connect_bd_intf_net [get_bd_intf_pins axi_vip/M_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_rewind/axi_phase_rew] -boundary_type upper [get_bd_intf_pins axi_interconnect/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_rewind/axi_offset_real] -boundary_type upper [get_bd_intf_pins axi_interconnect/M01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_rewind/axi_offset_imag] -boundary_type upper [get_bd_intf_pins axi_interconnect/M02_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_rewind/axi_phi_0] -boundary_type upper [get_bd_intf_pins axi_interconnect/M03_AXI]

### AXI Clock
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_vip/aclk]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/S00_ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/M00_ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/M01_ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/M02_ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_interconnect/M03_ACLK]
connect_bd_net [get_bd_ports axi_clk] [get_bd_pins axi_rewind/axi_clk]

### Device clk
connect_bd_net [get_bd_ports s_axis_aclk] [get_bd_pins axi_rewind/dev_clk]

### AXI aresetn
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_vip/aresetn]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/ARESETN]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/S00_ARESETN]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/M00_ARESETN]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/M01_ARESETN]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/M02_ARESETN]
connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_interconnect/M03_ARESETN]

connect_bd_net [get_bd_ports axi_aresetn] [get_bd_pins axi_rewind/axi_aresetn]

### dev rst
connect_bd_net [get_bd_ports s_axis_aresetn] [get_bd_pins axi_rewind/dev_rstn]


## Project
save_bd_design
validate_bd_design

set project_system_dir "./${project_name}/${project_name}.srcs/sources_1/bd/system"

set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
make_wrapper -files [get_files $project_system_dir/system.bd] -top

import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
#add_files -norecurse -fileset sources_1 [glob ./src/*]
set_property top system_wrapper [current_fileset]

### Simulation
add_files -fileset sim_1 -norecurse ./sim_full.sv
set_property top sim_full [get_filesets sim_1]


# Run
## Synthesis
#launch_runs synth_1
#wait_on_run synth_1
#open_run synth_1
#report_utilization -file "./utilization.txt" -name utilization_1

## Implementation
#set_property strategy Performance_Retiming [get_runs impl_1]
#launch_runs impl_1 -to_step write_bitstream
#wait_on_run impl_1
#open_run impl_1
#report_timing_summary -file timing_impl.log
