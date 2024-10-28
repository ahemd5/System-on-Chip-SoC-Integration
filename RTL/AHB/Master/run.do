vlib work
vlog *.*v
vsim -voptargs=+acc work.AHB_master_tb
do wave.do
run -all
