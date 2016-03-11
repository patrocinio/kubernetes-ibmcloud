# Installs the SoftLayer CLI
pip install --upgrade pip
pip install softlayer

KUBE_MASTER=kube-master
KUBE_NODE=kube-node
TIMEOUT=600

. ./kubernetes.cfg

# Args: $1: name
function create_server {
# Creates the machine
echo "Creating $1"
TEMP_FILE=/tmp/create-vs.out
yes | slcli vs create --hostname $1 --domain $DOMAIN --cpu 1 --memory 1 --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST > $TEMP_FILE
}

# Args: $1: name
function get_server_id {
# Extract virtual server ID
slcli vs list --hostname $1 --domain $DOMAIN | grep $1 > $TEMP_FILE
VS_ID=`cat $TEMP_FILE | awk '{print $1}'`
}

# Args: $1: name
function create_kube {
# Check whether kube master exists
TEMP_FILE=/tmp/deploy-kubernetes.out
slcli vs list --hostname $1 --domain $DOMAIN | grep $1 > $TEMP_FILE
COUNT=`wc $TEMP_FILE | awk '{print $1}'`

# Determine whether to create the kube-master
if [ $COUNT -eq 0 ]; then
create_server $1
else
echo "$1 already created"
fi

get_server_id $1

# Wait kube master to be ready
echo "Waiting for virtual server $1 to be ready"
slcli vs ready $VS_ID --wait=$TIMEOUT
}

# Arg $1: hostname
function obtain_root_pwd {
get_server_id $1

# Obtain the root password
slcli vs detail $VS_ID --passwords > $TEMP_FILE
PASSWORD=`grep root $TEMP_FILE | awk '{print $3}'`
echo PASSWORD $PASSWORD

}

# Args $1: hostname
function obtain_ip {
get_server_id $1
# Obtain the IP address
slcli vs detail $VS_ID --passwords > $TEMP_FILE
IP_ADDRESS=`grep public_ip $TEMP_FILE | awk '{print $2}'`
}


function configure_master {
# Get kube master password
obtain_root_pwd $KUBE_MASTER

# Get master IP address
obtain_ip $KUBE_MASTER
MASTER_IP=$IP_ADDRESS

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$MASTER_IP

# Get node IP address
obtain_ip $KUBE_NODE
NODE_IP=$IP_ADDRESS

# Update ansible hosts file
echo Updating ansible hosts files
HOSTS=/tmp/ansible-hosts
echo > $HOSTS
echo "[kube-master]" >> $HOSTS
echo "kube-master ansible_host=$MASTER_IP ansible_user=root" >> $HOSTS
echo "[kube-node]" >> $HOSTS
echo "kube-node ansible_host=$NODE_IP ansible_user=root" >> $HOSTS

# Create inventory file
INVENTORY=/tmp/inventory
echo > $INVENTORY
echo "[masters]" >> $INVENTORY
echo "kube-master" >> $INVENTORY
echo >> $INVENTORY
echo "[etcd]" >> $INVENTORY
echo "kube-master" >> $INVENTORY
echo >> $INVENTORY
echo "[nodes]" >> $INVENTORY
echo "kube-node" >> $INVENTORY

# Create ansible.cfg
ANSIBLE_CFG=/tmp/ansible.cfg
echo > $ANSIBLE_CFG
echo "[defaults]" >> $ANSIBLE_CFG
echo "host_key_checking = False" >> $ANSIBLE_CFG

# Execute kube-master playbook
ansible-playbook ansible/kube-master.yaml --extra-vars "kube_node=$NODE_IP"

}

function configure_node {
# Get kube master password
obtain_root_pwd $KUBE_NODE

# Get master IP address
obtain_ip $KUBE_NODE
NODE_IP=$IP_ADDRESS

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$NODE_IP

# Execute kube-master playbook
ansible-playbook ansible/kube-node.yaml
}


# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

create_kube $KUBE_MASTER
create_kube $KUBE_NODE

# Generate SSH key
yes | ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

configure_node
configure_master

echo "Congratulations! You can log on to the kube master by issuing ssh root@$MASTER_IP"







