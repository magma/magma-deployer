#!/bin/bash
echo wireshark-common/install-setuid wireshark-common/install-setuid select true|sudo debconf-set-selections
dpkg-reconfigure -f noninteractive wireshark-common
groupadd pcap
usermod -a -G pcap $1
usermod -a -G wireshark $1
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
# setcap cap_net_aw,cap_net_admin=eip /usr/sbin/tcpdump
setcap "CAP_NET_RAW+eip" /usr/sbin/tcpdump

