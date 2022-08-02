#run at juju ssh 0 

netplan_file=$(find /etc/netplan -name "*.yaml")

echo "File : $netplan_file"

eth1_ip=$(less $netplan_file| grep "192.168.230")a

echo "eth1: $eth1_ip"

eth2_ip=$(echo $eth1_ip| awk -F '.' '{print $4}'| cut -d '/' -f1)

echo "eth3: 192.168.231.$eth2_ip"

echo -e \
"   br-ex:\n"\
"      interfaces: [eno3]\n"\
"      addresses:\n"\
"      - 192.168.231.${eth2_ip}/24\n"\
"      gateway4: 192.168.231.1\n"\
"      mtu: 1500\n"  >> $netplan_file

netplan apply

ifconfig br-ex down
ifconfig br-ex up
ovs-vsctl add-port br-ex eno3
sleep 5
route add default gw 192.168.231.1 dev br-ex
ping -I br-ex 192.168.200.3

