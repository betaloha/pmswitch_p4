all: clean pmSwitch_request pmSwitch_ack pmSwitch_ack_gen

pmSwitch_request: pmSwitch_request.p4
	p4c-sdnet $@.p4 -o $@.sdnet --toplevel_name $@
	sdnet $@.sdnet -busType axi -workDir $@ -lineClock 300 -busWidth 64

pmSwitch_ack: pmSwitch_ack.p4
	p4c-sdnet $@.p4 -o $@.sdnet --toplevel_name $@
	sdnet $@.sdnet -busType axi -workDir $@ -lineClock 300 -busWidth 64

pmSwitch_ack_gen: pmSwitch_ack_gen.p4
	p4c-sdnet $@.p4 -o $@.sdnet --toplevel_name $@
	sdnet $@.sdnet -busType axi -workDir $@ -lineClock 300 -busWidth 64

clean:
	-rm -r *.sdnet pmSwitch_request pmSwitch_ack pmSwitch_ack_gen


