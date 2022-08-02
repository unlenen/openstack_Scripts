NEXUS_IP="10.10.1.159"


function create_volumes(){
	
	IMAGE_UBUNTU_18_ID=$(openstack image list | grep ubuntu18 | awk -F '|' '{print $2}')

	echo "[VOLUME][CREATE] k8s-nfs-1"
        openstack volume create --image $IMAGE_UBUNTU_18_ID  --size 300 --availability-zone nova k8s-nfs-1;
	
	for a in {1..3} ; do 
		echo "[VOLUME][CREATE] k8s-control-$a"
		openstack volume create --image $IMAGE_UBUNTU_18_ID --size 80 --availability-zone nova k8s-control-$a;
	done

	wait_to_volume_create

	for a in {1..12} ; do
        	echo "[VOLUME][CREATE] k8s-$a"
	        openstack volume create --image $IMAGE_UBUNTU_18_ID --size 160 --availability-zone nova k8s-worker-$a;
		
	done
}

function create_floating_ip(){

	FLOATING_IP_MAX=16
	FLOATING_IP_BEGIN=$(openstack floating ip list| grep "192." | grep -v "10."| wc -l)
	PUBLIC_NET_NAME="Pub_Net"


	for (( c=$FLOATING_IP_BEGIN; c<$FLOATING_IP_MAX; c++ ))
	do
		echo "[FLOATING_IP][CREATE]  public network : $PUBLIC_NET_NAME"
		openstack floating ip create ${PUBLIC_NET_NAME};
	done
}

function assign_floating_ip(){

	free_ip=$(openstack floating ip list| grep None | awk -F '|' '{print $3}'| head -n 1)
	openstack server add floating ip onap-nfs $free_ip 
	
	for a in {1..3}; do 
		free_ip=$(openstack floating ip list| grep None | awk -F '|' '{print $3}'| head -n 1)
		openstack server add floating ip onap-control-$a $free_ip 
		 echo "[FLOATING_IP][ASSIGN] onap-control-$a  --> $free_ip"
	 done

	for a in {1..12}; do 
		free_ip=$(openstack floating ip list| grep None | awk -F '|' '{print $3}'| head -n 1)
		openstack server add floating ip onap-k8s-$a $free_ip 
		echo "[FLOATING_IP][ASSIGN] onap-k8s-$a  --> $free_ip"
	done
}

function check_connection(){
	for a in $(openstack server list| awk -F '|' '{print $5}'| cut -d ',' -f2| grep 192); do  
		(echo >/dev/tcp/$a/22) &>/dev/null && echo "[Check][SSHConnection] $a open" || echo "[Check][SSHConnection] $a failed"  ; 
	done

}

function create_instances(){

	FLAVOR_CONTROLLER=$(openstack flavor list  | grep "k8s-controller" | awk -F '|' '{print $2}'| awk '{print $1}')
	FLAVOR_WORKER=$(openstack flavor list  | grep "k8s-worker" | awk -F '|' '{print $2}'| awk '{print $1}')
	FLAVOR_NFS=$(openstack flavor list  | grep "k8s-nfs" | awk -F '|' '{print $2}'| awk '{print $1}')

	NETWORK_ID=$( openstack network list| grep Onap_Network | awk -F '|' '{print $2}' | awk '{print $1}')
	IMAGE_ID=$( openstack image list | grep "ubuntu18.04"| awk -F '|' '{print $2}')
	SEC_GROUP_ID=$( openstack security group list| grep "allow_ssh" |awk -F '|' '{print $2}' | awk '{print $1}')


	VOLUME_ID=$(openstack volume list| grep "k8s-nfs-1 "| awk -F '|' '{print $2}' |awk '{print $1}' )
	echo "[Create][onap-nfs] from volume [$VOLUME_ID]"

	openstack server create --flavor ${FLAVOR_NFS} --image $IMAGE_ID  --nic net-id=$NETWORK_ID --key-name=cloud --security-group $SEC_GROUP_ID --user-data ./inst-script/openstack-nfs-server.sh onap-nfs

	cp ./inst-script/openstack-k8s-controlnode.sh ./inst-script/openstack-k8s-controlnode_new.sh
	sed "s#192.168.240.251#$NEXUS_IP#g" -i ./inst-script/openstack-k8s-controlnode_new.sh
	for a in {1..3}; do 
	
		VOLUME_ID=$(openstack volume list| grep "k8s-control-$a "| awk -F '|' '{print $2}' |awk '{print $1}' )
	
		echo "[Create][onap-control-$a] from volume [$VOLUME_ID]"
		
		openstack server create --flavor ${FLAVOR_CONTROLLER} --image $IMAGE_ID  --nic net-id=$NETWORK_ID --key-name=cloud --security-group $SEC_GROUP_ID --user-data ./inst-script/openstack-k8s-controlnode_new.sh  onap-control-$a
	done

	cp ./inst-script/openstack-k8s-workernode.sh ./inst-script/openstack-k8s-workernode_new.sh
	sed "s#192.168.240.251#$NEXUS_IP#g" -i ./inst-script/openstack-k8s-workernode_new.sh
	for a in {1..12}; do 

		VOLUME_ID=$(openstack volume list| grep "k8s-worker-$a "| awk -F '|' '{print $2}' |awk '{print $1}' )
	
		echo "[Create][onap-worker-$a] from volume [$VOLUME_ID]"

		openstack server create --flavor ${FLAVOR_WORKER} --image $IMAGE_ID  --nic net-id=$NETWORK_ID --key-name=cloud --security-group $SEC_GROUP_ID --user-data ./inst-script/openstack-k8s-workernode_new.sh  onap-k8s-$a
	done
}


function wait_to_volume_create(){
	printf "Volumes are creating " ; until [[ -z $(openstack volume list| grep k8s | grep -v available) ]] ; do   printf "." ;   sleep 1s;          done
	echo ""
}


function wait_to_instance_create(){
        printf "Instance are creating " ; until [[ -z $(openstack server list| grep onap |awk -F '|' '{print $4}'| grep -v ACTIVE) ]] ; do   printf "." ;   sleep 1s;          done
        echo ""
}


function prepare_nfs_node(){
	worker_ips=$(openstack server list| awk -F '|' '{print $5}'| awk -F ',' '{print $1}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | tr '\n' ' ')
	
	nfs_server_ip=$( get_server_public_ip "onap-nfs")
	master_script_file="./inst-script/master_nfs_node.sh"
	public_key="./unlenen.pem"

	remote="/home/ubuntu"

	scp -o UserKnownHostsFile=/dev/null -o 'StrictHostKeyChecking=no' -i ${public_key} ${master_script_file} ubuntu@${nfs_server_ip}:${remote}

	echo "[NFS][MASTER] $master_script_file sent to $nfs_server_ip"

	command="chmod +x  ${remote}/master_nfs_node.sh;  sudo ${remote}/master_nfs_node.sh ${worker_ips}"

	echo "[NFS][MASTER] Creating NFS Server"
	output=$(ssh -o UserKnownHostsFile=/dev/null -o 'StrictHostKeyChecking=no' -i ${public_key} ubuntu@${nfs_server_ip} -t "sudo bash -c '${command}' ")
	echo "[NFS][MASTER]  NFS Server is created"
	
}

function prepare_nfs_worker_node(){
	nfs_server_ip=$( get_server_private_ip "onap-nfs")
#	nfs_server_ip="192.168.230.21"
	slave_script_file="./inst-script/slave_nfs_node.sh"
	public_key="./unlenen.pem"
	remote="/home/ubuntu"


	for a in $(openstack server list| grep "onap-k8s"| awk -F '|' '{print $5}'| cut -d ',' -f2| grep 192);do
		server="$a"
		remote="/home/ubuntu"
		
		scp -o UserKnownHostsFile=/dev/null -o 'StrictHostKeyChecking=no' -i ${public_key} ${slave_script_file} ubuntu@${server}:${remote} 
		
		echo "[NFS][SLAVE] $slave_script_file sent to $server"
		
		command="chmod +x ${remote}/slave_nfs_node.sh;sudo ${remote}/slave_nfs_node.sh ${nfs_server_ip}"
		
		ssh -o UserKnownHostsFile=/dev/null -o 'StrictHostKeyChecking=no' -i ${public_key} ubuntu@${server} -t "sudo bash -c '${command}' "
		
		echo "[NFS][SLAVE] server:${server} Mount to Nfs Server is completed"

	done;
}

function get_server_public_ip(){
	node_name="$1"
	openstack server list|grep "$node_name"| awk -F '|' '{print $5}'| awk -F ',' '{print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"
}

function get_server_private_ip(){
        node_name="$1"
        openstack server list|grep "$node_name"| awk -F '|' '{print $5}'| awk -F ',' '{print $1}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"
}


function main(){
	source Onap.rc
#	create_volumes
#	wait_to_volume_create
	create_instances
	create_floating_ip	
	assign_floating_ip
	wait_to_instance_create
	check_connection
	prepare_nfs_node
	prepare_nfs_worker_node
}

main
