openstack flavor create --id 0 --ram 512   --vcpus 1 --disk 10  m1.tiny
openstack flavor create --id 1 --ram 1024  --vcpus 1 --disk 20  m1.small
openstack flavor create --id 2 --ram 2048  --vcpus 2 --disk 40  m1.medium
openstack flavor create --id 3 --ram 4096  --vcpus 2 --disk 80  m1.large
openstack flavor create --id 4 --ram 8192  --vcpus 4 --disk 160 m1.xlarge
openstack flavor create --id 5 --ram 8192  --vcpus 4 --disk 80 k8s-controller
openstack flavor create --id 6 --ram 16384  --vcpus 8 --disk 160 k8s-worker
openstack flavor create --id 7 --ram 8192  --vcpus 4 --disk 300 k8s-nfs

