default: build

CPU_TYPE = vexriscv

build-prebuild:
	python3 etpu_soc.py --build --cpu-type $(CPU_TYPE) --cpu-variant minimal+debug


build: firmware/firmware_build.bin
	python3 etpu_soc.py --rom-init=firmware/firmware_build.bin --with-led-chaser --build --cpu-type $(CPU_TYPE) --cpu-variant minimal+debug

upload: build
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

only-upload:
	openFPGALoader --board=ulx3s build/radiona_ulx3s/gateware/radiona_ulx3s.bit

view:
	gtkwave build/sim/gateware/sim.fst --save build/sim/gateware/sim.gtkw 

.PHONY: sim build upload only-upload view firmware/firmware_build.bin firmware/firmware_sim.bin
