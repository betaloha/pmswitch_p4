//#include <core.p4>
#include <xilinx.p4>

// Const defs
const bit<16> TYPE_IPV4 = 0x800;
const bit<8> IPV4_PROTOCOL_UDP = 0x11;
const bit<8> PMSWITCH_OPCODE_INVALID = 0x00;
const bit<8> PMSWITCH_OPCODE_PERSIST_NEED_ACK = 0x01;
const bit<8> PMSWITCH_OPCODE_ACK = 0x02;
const bit<8> PMSWITCH_OPCODE_PERSIST_NO_ACK = 0x03;
const bit<8> PMSWITCH_OPCODE_REPONSE = 0x04;
const bit<16> PMSWITCH_PORT = 51000;
typedef bit<48>     MacAddress;
typedef bit<32>     IPv4Address;
typedef bit<128>    IPv6Address;
header ethernet_h {
    MacAddress          dst;
    MacAddress          src;
    bit<16>             type;
}

header ipv4_h {
    bit<4>              version;
    bit<4>              ihl;
    bit<8>              tos;
    bit<16>             len;
    bit<16>             id;
    bit<3>              flags;
    bit<13>             frag;
    bit<8>              ttl;
    bit<8>              proto;
    bit<16>             chksum;
    IPv4Address         src;
    IPv4Address         dst;
}

// header ipv6_h {
//     bit<4>              version;
//     bit<8>              tc;
//     bit<20>             fl;
//     bit<16>             plen;
//     bit<8>              nh;
//     bit<8>              hl;
//     IPv6Address         src;
//     IPv6Address         dst;
// }

header udp_h {
    bit<16>             sport;
    bit<16>             dport;
    bit<16>             len;
    bit<16>             chksum;
}

header pmswitchhds_h {
    bit<8> type;            // Type of PMSwitch package: PERSIST_NEED_ACK, BYPASS or ACK_PERSIST
    bit<16> session_id;
    bit<32> seq_no;
}

struct headers {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    // ipv6_h       ipv6;
    udp_h        udp;
    pmswitchhds_h pmswitchhds;
}
// Xilinx-specific max packet size primitive


// Parsers
@Xilinx_MaxPacketRegion(4500*8)  // in bits
parser PMSwitchParser(packet_in pkt,
                      out headers hdr){
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x0800  : parse_ipv4;
            // 0x86DD  : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.proto) {
            // 6       : parse_tcp;
            17      : parse_udp;
            default : accept;
        }
    }

    // state parse_ipv6 {
    //     pkt.extract(hdr.ipv6);
    //     transition select(hdr.ipv6.nh) {
    //         // 6       : parse_tcp;
    //         17      : parse_udp;
    //         default : accept;
    //     }
    // }

    // state parse_tcp {
    //     pkt.extract(hdr.tcp);
    //     transition accept;
    // }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dport){
            PMSWITCH_PORT   : parse_PMSwitch;
            default         : accept;
        }
    }

    state parse_PMSwitch{
        pkt.extract(hdr.pmswitchhds);
        transition accept;
    }

}
// TO DO: complete this.
// Processing
control PMSwitchProcessing(inout headers hdr,
                  inout switch_metadata_t ctrl) {
    action forwardPacket(switch_port_t value) {
        ctrl.egress_port = value;
    }
    action dropPacket() {
        ctrl.egress_port = 0xF;
    }
    
    table forwardIPv4 {
        key             = { hdr.ipv4.dst : ternary; }
        actions         = { forwardPacket; dropPacket; }
        size            = 63;
        default_action  = dropPacket;
    }
    

    apply {
        if (hdr.ipv4.isValid()){
            if(hdr.udp.isValid()){
                if(hdr.udp.dport == PMSWITCH_PORT){
                    if(hdr.pmswitchhds.isValid()){
                        if(hdr.pmswitchhds.type == PMSWITCH_OPCODE_PERSIST_NEED_ACK){
                            // Forward the request to memctl part.



                        }
                    }
                }
            }
            // Apply IPv4 routing
            forwardIPv4.apply();
            // How can we detect or change route when link "failure" happens?
        }

    }
}

// Deparser
@Xilinx_MaxPacketRegion(4500*8)  // in bits
control PMSwitchDeparser(in headers hdr, packet_out packet) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        // pkt.emit(hdr.ipv6);
        packet.emit(hdr.udp);
        packet.emit(hdr.pmswitchhds);
    }
}
XilinxSwitch(PMSwitchParser(), PMSwitchProcessing(), PMSwitchDeparser()) main;
