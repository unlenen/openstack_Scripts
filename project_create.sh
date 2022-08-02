DOMAIN_NAME="unlenen"
PROJECT_NAME="onap"
USER_NAME="onap_user"
USER_PASS="defne"
ROLE_NAME="Admin"


openstack domain create $DOMAIN_NAME
openstack project create --domain $DOMAIN_NAME $PROJECT_NAME
openstack user create --domain $DOMAIN_NAME --password $USER_PASS $USER_NAME

USER_ID=$(openstack user list --domain $DOMAIN_NAME|grep $USER_NAME| awk -F '|' '{print $2}'| awk '{print $1}')

openstack role add --project $PROJECT_NAME --user $USER_ID $ROLE_NAME
