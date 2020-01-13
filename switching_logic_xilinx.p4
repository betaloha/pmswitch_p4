#include <core.p4>
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

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> destPort;
    bit<16> udplength;
    bit<16> udpChecksum;
}

header pmswitchhds_t {
    bit<8> type;            // Type of PMSwitch package: PERSIST_NEED_ACK, BYPASS or ACK_PERSIST
    bit<16> session_id;
    bit<32> seq_no;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
    pmswitchhds_t pmswitchhds;
}
// Xilinx-specific max packet size primitive


// Parsers
@Xilinx_MaxPacketRegion(4500*8)  // in bits
parser PMSwitchParser(packet_in packet,
                      out headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata){
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            IPV4_PROTOCOL_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.destPort){
            PMSWITCH_PORT: parse_PMSwitch;
            default: accept;
        }
        
    }

    state parse_PMSwitch{
        packet.extract(hdr.pmswitchhds);
        transition accept;
    }

}
// TO DO: complete this.
// Processing
control PMSwitchProcessing(inout headers hdr,
                  inout switch_metadata_t ctrl) {
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    

    apply {
        if (hdr.ipv4.isValid()){
            if(hdr.udp.isValid()){
                if(hdr.udp.destPort == PMSWITCH_PORT){
                    if(hdr.pmswitchhds.isValid()){
                        if(hdr.pmswitchhds.type == PMSWITCH_OPCODE_PERSIST_NEED_ACK){
                            // Forward the request to memctl part.



                        }
                    }
                }
            }
            // Apply IPv4 routing
            ipv4_lpm.apply();
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
        packet.emit(hdr.udp);
        packet.emit(hdr.pmswitchhds);
    }
}