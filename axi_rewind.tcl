set ip_name "axi_rewind"
create_project $ip_name "./${ip_name}" -force -part "xczu28dr-ffvg1517-2-e"
#set_property board_part xilinx.com:zcu111:part0:1.4 [current_project]
source ./util.tcl

create_bd_design "axi_rewind"
update_compile_order -fileset sources_1

# IP repository setting to import "rewind" core produced by Vitis HLS
set_property  ip_repo_paths "./hls/proj_rewind/solution1/impl/ip" [current_project]
update_ip_catalog

# Implementation of rewind core
create_bd_cell -type ip -vlnv [latest_ip rewind] rewind

# Block memory
create_bd_cell -type ip -vlnv [latest_ip blk_mem_gen] bram_phase_rew
create_bd_cell -type ip -vlnv [latest_ip blk_mem_gen] bram_offset_real
create_bd_cell -type ip -vlnv [latest_ip blk_mem_gen] bram_offset_imag
create_bd_cell -type ip -vlnv [latest_ip blk_mem_gen] bram_phi_0

connect_bd_intf_net [get_bd_intf_pins rewind/phase_rew_PORTA]   [get_bd_intf_pins bram_phase_rew/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins rewind/offset_real_PORTA] [get_bd_intf_pins bram_offset_real/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins rewind/offset_imag_PORTA] [get_bd_intf_pins bram_offset_imag/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins rewind/phi_0_PORTA]       [get_bd_intf_pins bram_phi_0/BRAM_PORTA]

set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM}] [get_bd_cells bram_phase_rew]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM}] [get_bd_cells bram_offset_real]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM}] [get_bd_cells bram_offset_imag]
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM}] [get_bd_cells bram_phi_0]

create_bd_cell -type ip -vlnv [latest_ip axi_bram_ctrl] axi_bc_phase_rew
create_bd_cell -type ip -vlnv [latest_ip axi_bram_ctrl] axi_bc_offset_real
create_bd_cell -type ip -vlnv [latest_ip axi_bram_ctrl] axi_bc_offset_imag
create_bd_cell -type ip -vlnv [latest_ip axi_bram_ctrl] axi_bc_phi_0

set_property -dict [list CONFIG.DATA_WIDTH {32} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bc_phase_rew]
set_property -dict [list CONFIG.DATA_WIDTH {32} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bc_offset_real]
set_property -dict [list CONFIG.DATA_WIDTH {32} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bc_offset_imag]
set_property -dict [list CONFIG.DATA_WIDTH {32} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bc_phi_0]

connect_bd_intf_net [get_bd_intf_pins axi_bc_phase_rew/BRAM_PORTA]   [get_bd_intf_pins bram_phase_rew/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axi_bc_offset_real/BRAM_PORTA] [get_bd_intf_pins bram_offset_real/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axi_bc_offset_imag/BRAM_PORTA] [get_bd_intf_pins bram_offset_imag/BRAM_PORTB]
connect_bd_intf_net [get_bd_intf_pins axi_bc_phi_0/BRAM_PORTA]       [get_bd_intf_pins bram_phi_0/BRAM_PORTB]

# Clock and reset
## Device clock (expected to be 256 MHz)
create_bd_net dev_clk
create_bd_port -dir I -type clk -freq_hz 256000000 dev_clk
connect_bd_net -net [get_bd_nets dev_clk] [get_bd_ports dev_clk]
connect_bd_net -net [get_bd_nets dev_clk] [get_bd_pins rewind/ap_clk]

## Device reset
create_bd_net dev_rstn
create_bd_port -dir I -type rst dev_rstn
connect_bd_net -net [get_bd_nets dev_rstn] [get_bd_ports dev_rstn]
connect_bd_net -net [get_bd_nets dev_rstn] [get_bd_pins rewind/ap_rst_n]

## AXI clock
create_bd_net axi_clk
create_bd_port -dir I -type clk axi_clk
connect_bd_net -net [get_bd_nets axi_clk] [get_bd_ports axi_clk]

connect_bd_net -net [get_bd_nets axi_clk] [get_bd_pins axi_bc_phase_rew/s_axi_aclk]
connect_bd_net -net [get_bd_nets axi_clk] [get_bd_pins axi_bc_offset_real/s_axi_aclk]
connect_bd_net -net [get_bd_nets axi_clk] [get_bd_pins axi_bc_offset_imag/s_axi_aclk]
connect_bd_net -net [get_bd_nets axi_clk] [get_bd_pins axi_bc_phi_0/s_axi_aclk]

## AXI resetn
create_bd_net axi_aresetn
create_bd_port -dir I -type rst axi_aresetn
connect_bd_net -net [get_bd_nets axi_aresetn] [get_bd_pins axi_bc_phase_rew/s_axi_aresetn]
connect_bd_net -net [get_bd_nets axi_aresetn] [get_bd_pins axi_bc_offset_real/s_axi_aresetn]
connect_bd_net -net [get_bd_nets axi_aresetn] [get_bd_pins axi_bc_offset_imag/s_axi_aresetn]
connect_bd_net -net [get_bd_nets axi_aresetn] [get_bd_pins axi_bc_phi_0/s_axi_aresetn]
connect_bd_net -net [get_bd_nets axi_aresetn] [get_bd_ports axi_aresetn] 

# AXI interfaces
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi_phase_rew
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi_offset_real
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi_offset_imag
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 axi_phi_0

connect_bd_intf_net [get_bd_intf_ports axi_phase_rew] [get_bd_intf_pins axi_bc_phase_rew/S_AXI]
connect_bd_intf_net [get_bd_intf_ports axi_offset_real] [get_bd_intf_pins axi_bc_offset_real/S_AXI]
connect_bd_intf_net [get_bd_intf_ports axi_offset_imag] [get_bd_intf_pins axi_bc_offset_imag/S_AXI]
connect_bd_intf_net [get_bd_intf_ports axi_phi_0] [get_bd_intf_pins axi_bc_phi_0/S_AXI]

# AXIS interfaces
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axis_data_in
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {1} \
                         CONFIG.HAS_TKEEP {1} \
                         CONFIG.HAS_TSTRB {1} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.TDATA_NUM_BYTES {12}] [get_bd_intf_ports axis_data_in]
connect_bd_intf_net [get_bd_intf_ports axis_data_in] [get_bd_intf_pins rewind/data_in]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axis_phase_out
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {0} \
                         CONFIG.HAS_TKEEP {0} \
                         CONFIG.HAS_TSTRB {0} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.TDATA_NUM_BYTES {8}] [get_bd_intf_ports axis_phase_out]
connect_bd_intf_net [get_bd_intf_ports axis_phase_out] [get_bd_intf_pins rewind/data_out]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axis_data_out
set_property -dict [list CONFIG.FREQ_HZ {256000000} \
                         CONFIG.HAS_TLAST {1} \
                         CONFIG.HAS_TKEEP {1} \
                         CONFIG.HAS_TSTRB {1} \
                         CONFIG.HAS_TREADY {1} \
                         CONFIG.TDATA_NUM_BYTES {12}] [get_bd_intf_ports axis_data_out]
connect_bd_intf_net [get_bd_intf_ports axis_data_out] [get_bd_intf_pins rewind/data_pipe]




save_bd_design
validate_bd_design

ipx::package_project -root_dir "./ip_repo" -vendor kuhep -library user -taxonomy /UserIP -module axi_rewind -import_files

set axi_rewind [ipx::find_open_core kuhep:user:axi_rewind:1.0]

set_property display_name axi_rewind                                  $axi_rewind
set_property description {Rewind KIDs response to yield phase signal} $axi_rewind
set_property vendor_display_name kuhep                                $axi_rewind
set_property core_revision 2                                          $axi_rewind

ipx::create_xgui_files                                                $axi_rewind
ipx::update_checksums                                                 $axi_rewind
ipx::check_integrity                                                  $axi_rewind
ipx::save_core                                                        $axi_rewind
#set_property  ip_repo_paths  {"./ip_repo" "./hls/proj_rewind/solution1/impl/ip"} [current_project]
#update_ip_catalog
