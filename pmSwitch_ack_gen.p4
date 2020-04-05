#include "xilinx_custom.p4"
#include "common.p4"

control PMSwitchProcessing(inout headers hdr,
                  inout PMswitch_metadata_t ctrl) {
    action genAck() {
        /*ctrl.PMSwitchOPS    = hdr.pmswitchhds.type;
        ctrl.hashedAddress  = hdr.pmswitchhds.PMAddress;
        ctrl.ackCount       = hdr.pmswitchhds.ackCount;
        */
        // Swap src and dst of ethernet MAC and IPv4
        IPv4Address sourceAddr = hdr.ipv4.src;
        hdr.ipv4.src = hdr.ipv4.dst;
        hdr.ipv4.dst = sourceAddr;
        // Swap Src and Dst UDP port
        bit<16> sourcePort = hdr.udp.sport;
        hdr.udp.sport = hdr.udp.dport;
        hdr.udp.dport = sourcePort;
        // Swap Src and Dst MAC address
        MacAddress srcMac = hdr.ethernet.src;
        hdr.ethernet.src = hdr.ethernet.dst;
        hdr.ethernet.dst = srcMac;

        // Change PMSwitch OPS to switch ACK
        hdr.pmswitchhds.type = PMSWITCH_OPCODE_ACK;

    }
    action bypass() {
        ctrl.PMSwitchOPS    = PMSWITCH_OPCODE_NOOP;
        ctrl.hashedAddress  = INVALID_ADDR;
        ctrl.ackCount       = 0xFF;
    }

     apply {
        //  We still need to filter out the packet from the processor.
        if (hdr.ipv4.isValid()&& hdr.udp.isValid() && hdr.pmswitchhds.isValid()){
            if((hdr.pmswitchhds.type == PMSWITCH_OPCODE_PERSIST_NEED_ACK)){
                genAck();
            }else{
                bypass();
            }
        }else{
            bypass();
        }
    }
}

XilinxSwitch(PMSwitchCommonParser(), PMSwitchProcessing(), PMSwitchCommonDeparser()) main;