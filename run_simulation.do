# mohamed 
# Redirect output to a log file
write transcript transcript_log.txt

# Define variables for the top module name and simulation duration
# Replace 'top_module_name' with the name of your top-level module.
set TOP_MODULE tb_Sync_FIFO ;
set SIM_TIME "1000ns"  ; # Set the duration of the simulation (can also use 'run -all' for indefinite simulation time)

# Step 1: Create the "work" library if it does not already exist
if {![file exists work]} {
    vlib work;  # Create a new library named "work" to store compiled files
}

# Step 2: Map the "work" library so that ModelSim knows where to find it
vmap work work;  # Map the "work" library to itself, allowing ModelSim to locate it during simulation

# Step 3: Check for files and compile all .sv and .v files in the current directory
# Using [glob *.sv *.v] to find all Verilog (.v) and SystemVerilog (.sv) files in the current directory
set file_list [glob *.sv *.v];
if {[llength $file_list] == 0} {
    # Display an error message and exit if no files are found;
    puts "Error: No .sv or .v files found in the current directory.";
    quit  # Exit the script if no files are present ;
}

# Loop through each file in the file list and compile them
foreach file $file_list {
    vlog -sv $file ;  # Compile the current file using the SystemVerilog compiler
}

# Step 4: Load the top module into the simulator and set simulation options
# Load the top-level module specified by the TOP_MODULE variable into the simulator
vsim -L work -voptargs=+acc work.$TOP_MODULE;

# Step 5: Configure simulation settings
# Enable signal tracing for debugging purposes
log -r /* ; # Log all signals for analysis during simulation
# Set the message severity level to include warnings
set MsgSeverity("WARNING") "ON" ; # Enable warnings to help identify potential issues

# Add all signals to the waveform window for visual debugging
add wave -r /* ; # Ensure that all signals are included in the waveform for monitoring

# save the waveform setup to a .do file for future sessions
write wave -do wave.do;

# Step 6: Run the simulation
# Use 'run -all' for full simulation duration or the specified time limit with the SIM_TIME variable
if {$SIM_TIME == "all"} {
    run -all ;  # Run the simulation indefinitely if SIM_TIME is set to "all"
} else {
    run $SIM_TIME ;  # Run the simulation for the duration specified in SIM_TIME
}

# Step 7: Save waveform data for post-simulation analysis
# Save the waveform file to view signals after quitting the simulation
# Write the waveform data to a .wlf file named after the top module
write wave -file $TOP_MODULE.wlf;

# Step 8: Quit ModelSim after the simulation finishes
quit;  # Exit ModelSim and clean up the simulation environment.




