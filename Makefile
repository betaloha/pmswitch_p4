all: clean req ack

req: pmSwitch_req.p4
	p4c-sdnet pmSwitch_req.p4 -o pmSwitch_req.sdnet
	sdnet pmSwitch_req.sdnet -busType axi -workDir pmSwitch_req -lineClock 157 -busWidth 64

ack: pmSwitch_ack.p4
	p4c-sdnet pmSwitch_ack.p4 -o pmSwitch_ack.sdnet
	sdnet pmSwitch_ack.sdnet -busType axi -workDir pmSwitch_ack -lineClock 157 -busWidth 64

clean:
	-rm -r *.sdnet pmSwitch_req pmSwitch_ack
