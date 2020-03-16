all: clean pmSwitch_switch

pmSwitch_switch: pmSwitch_switch.p4
	p4c-sdnet pmSwitch_switch.p4 -o pmSwitch_switch.sdnet
	sdnet pmSwitch_switch.sdnet -busType axi -workDir pmSwitch_switch -lineClock 157 -busWidth 64
	
clean:
	-rm -r *.sdnet pmSwitch_switch
