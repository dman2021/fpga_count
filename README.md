Run these commands to install and run:
yosys -p "synth_ecp5 -json top.json" top.v
nextpnr-ecp5 --json top.json --lpf top.lpf --textcfg top.config --85k --package CABGA381
ecppack top.config top.bit
sudo openFPGALoader -b ulx3s top.bit
