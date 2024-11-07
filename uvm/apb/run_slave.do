vlib work
vlog apb_config_pkg.sv apb_master.sv apb_slave.sv master_arb_if.sv slave_arb_if.sv master_apb_seq_item_pkg.sv slave_apb_seq_item_pkg.sv master_apb_main_sequence_pkg.sv slave_apb_main_sequence_pkg.sv slave_apb_sequencer_pkg.sv master_apb_sequencer_pkg.sv master_apb_driver_pkg.sv slave_apb_driver_pkg.sv slave_apb_agent_pkg.sv master_apb_agent_pkg.sv wait_sequence.sv read_mast_seq.sv apb_coverage_pkg.sv apb_scoreboard_pkg.sv apb_env_pkg.sv apb_test_pkg.sv TOP.sv  +cover -covercells
vsim -voptargs=+acc work.apb_top -cover
add wave -position insertpoint sim:/apb_top/slv_inter/*
add wave /apb_top/dut2/assert__reset_behavior /apb_top/dut2/assert__valid_transition_from_idle /apb_top/dut2/assert__write_state_data_control /apb_top/dut2/assert__read_state_data_control /apb_top/dut2/assert__pready_assertion /apb_top/dut2/assert__valid_assertion_in_idle
coverage save slave.ucdb -onexit -du apb_slave
run -all
vcover report slave.ucdb -details -annotate -all -output coverage_rpt_slave.txt



