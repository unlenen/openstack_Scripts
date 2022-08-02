

PROJECT_NAME="onap"

CPU_SIZE=$( openstack hypervisor list --long|grep QEMU| awk -F '|' '{print $8}'| awk '{print $1}'| awk '{s+=$1} END {print s}')

RAM_SIZE=$( openstack hypervisor list --long|grep QEMU| awk -F '|' '{print $10}'| awk '{print $1}'| awk '{s+=$1} END {print s}')


QUOTA="openstack quota set $PROJECT_NAME"

$QUOTA --cores $CPU_SIZE
$QUOTA --ram  $RAM_SIZE
$QUOTA --key-pairs 1000
$QUOTA --floating-ips 254
$QUOTA --instances $CPU_SIZE
$QUOTA --fixed-ips 1000
$QUOTA --server-groups 1000
$QUOTA --server-group-members 1000

$QUOTA --volumes 10000
$QUOTA --gigabytes 10000

$QUOTA --ports=1000
$QUOTA --networks=1000
$QUOTA --routers=100
$QUOTA --subnets=100
$QUOTA --floating-ips=1000


openstack quota list --compute --project onap
openstack quota list --volume --project onap

openstack quota list --network --project onap
