PUBLIC_NETWORK_NAME="Pub_Net"
PUBLIC_SUBNET_NAME="Pub_Subnet"
PUBLIC_GW="192.168.231.1"
PUBLIC_NET_CIDR="192.168.231/24"
PUBLIC_NET_START="192.168.231.22"
PUBLIC_NET_END="192.168.231.240"


PRIVATE_PROJECT_NAME="onap"
PRIVATE_NETWORK_NAME="Onap_Network"
PRIVATE_SUBNET_NAME="Onap_Subnet"
PRIVATE_GW="10.10.1.1"
PRIVATE_NET_DNS="8.8.8.8"
PRIVATE_NET_CIDR="10.10.1.0/16"
PRIVATE_NET_START="10.10.1.2"
PRIVATE_NET_END="10.10.254.254"


ROUTER_NAME="Onap_Router"


openstack network create $PUBLIC_NETWORK_NAME --external --share --default    --provider-network-type flat --provider-physical-network physnet1
openstack subnet create $PUBLIC_SUBNET_NAME --allocation-pool start=${PUBLIC_NET_START},end=${PUBLIC_NET_END} \
   --subnet-range $PUBLIC_NET_CIDR --no-dhcp --gateway $PUBLIC_GW \
   --network $PUBLIC_NETWORK_NAME

openstack network create --project $PRIVATE_PROJECT_NAME  $PRIVATE_NETWORK_NAME --internal
openstack subnet create  --project $PRIVATE_PROJECT_NAME $PRIVATE_SUBNET_NAME \
   --allocation-pool start=$PRIVATE_NET_START,end=$PRIVATE_NET_END \
   --subnet-range $PRIVATE_NET_CIDR \
   --gateway $PRIVATE_GW --dns-nameserver $PRIVATE_NET_DNS \
   --network $PRIVATE_NETWORK_NAME


openstack router create --project $PRIVATE_PROJECT_NAME $ROUTER_NAME
openstack router add subnet $ROUTER_NAME $PRIVATE_SUBNET_NAME
openstack router set $ROUTER_NAME --external-gateway $PUBLIC_NETWORK_NAME



