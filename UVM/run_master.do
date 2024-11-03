vlib work
vlog apb_config_pkg.sv apb_master.sv apb_slave.sv master_arb_if.sv slave_arb_if.sv master_apb_seq_item_pkg.sv slave_apb_seq_item_pkg.sv master_apb_main_sequence_pkg.sv slave_apb_main_sequence_pkg.sv slave_read_seq.sv slave_apb_sequencer_pkg.sv master_apb_sequencer_pkg.sv master_apb_driver_pkg.sv slave_apb_driver_pkg.sv slave_apb_agent_pkg.sv master_apb_agent_pkg.sv wait_sequence.sv read_mast_seq.sv apb_coverage_pkg.sv apb_scoreboard_pkg.sv apb_env_pkg.sv apb_test_pkg.sv TOP.sv  +cover -covercells
vsim -voptargs=+acc work.apb_top -cover
add wave -position insertpoint sim:/apb_top/mast_inter/*
add wave /apb_top/dut1/assert__p1 /apb_top/dut1/assert__p2 /apb_top/dut1/assert__p3 /apb_top/dut1/assert__p4 /apb_top/dut1/assert__p5 /apb_top/dut1/assert__p6 /apb_top/dut1/assert__p7 /apb_top/dut1/assert__p8 /apb_top/dut1/assert__p9 /apb_top/dut1/assert__p10 /apb_top/dut1/assert__idle_state /apb_top/dut1/assert__setup_state /apb_top/dut1/assert__access_wait_state /apb_top/dut1/assert__access_last_state /apb_top/dut1/assert__pwdata_in_wr_transfer /apb_top/dut1/assert__penable_in_transfer /apb_top/dut1/assert__psel_stable_in_transfer
coverage save Mem.ucdb -onexit -du apb_master
run -all
vcover report Mem.ucdb -details -annotate -all -output coverage_rpt.txt



