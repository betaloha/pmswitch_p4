#include "xilinx_custom.p4"
#include "common.p4"

control PMSwitchAckProcessing(inout headers hdr,
                  inout PMswitch_metadata_t ctrl) {
    action AccessMemory() {
        ctrl.PMSwitchOPS    = hdr.pmswitchhds.type;
        ctrl.hashedAddress  = hdr.pmswitchhds.PMAddress;
        ctrl.ackCount       = 0xFF;
    }
    action bypass() {
        ctrl.PMSwitchOPS    = PMSWITCH_OPCODE_NOOP;
        ctrl.hashedAddress  = INVALID_ADDR;
        ctrl.ackCount       = 0xFF;
    }

     apply {
        //  We still need to filter out the packet from the processor.
        if (hdr.ipv4.isValid()&& hdr.udp.isValid() && hdr.pmswitchhds.isValid()){
            if((hdr.pmswitchhds.type == PMSWITCH_OPCODE_REPONSE)||(hdr.pmswitchhds.type == PMSWITCH_OPCODE_ACK)){
                AccessMemory();
            }else{
                bypass();
            }
        }else{
            bypass();
        }
    }
}

XilinxSwitch(PMSwitchCommonParser(), PMSwitchAckProcessing(), PMSwitchCommonDeparser()) main;