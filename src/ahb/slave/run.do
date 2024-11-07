vlib work
vlog *.*v
vsim -voptargs=+acc work.AHB_slave_TB
do wave.do
run -all
