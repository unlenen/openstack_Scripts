cd ./images/
for a in $(find ./ -name "*.img") ; do 
	name=$(echo $a | sed 's#.img##g'| sed 's#./##g')
	echo $name
	openstack image create --public --container-format=bare --disk-format=qcow2 $name --file $a;
done
