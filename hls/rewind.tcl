open_project -reset proj_rewind

# Add design files
add_files rewind.cpp
add_files rewind.hpp
# Add test bench & files
add_files -tb rewind_test.cpp


# Set the top-level function
set_top rewind

# ########################################################
# Create a solution
open_solution -reset solution1 -flow_target vivado

# Define technology and clock rate
set_part {xczu28dr-ffvg1517-2-e}
create_clock -period 2
set_clock_uncertainty 0.2

csynth_design
export_design -format ip_catalog

exit
