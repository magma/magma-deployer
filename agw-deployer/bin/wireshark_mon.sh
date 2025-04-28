INTERFACE=$1
test -n "${INTERFACE}" || INTERFACE="eth1"
echo "Watching ${INTERFACE}"
sudo dumpcap -s 0 -n -i ${INTERFACE} -w - |wireshark -k -i -
