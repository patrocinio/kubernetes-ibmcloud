# Installs the SoftLayer CLI
pip install --upgrade pip
pip install softlayer

KUBE_MASTER_PREFIX=kube-master-
KUBE_NODE_PREFIX=kube-node-
TIMEOUT=600

. ./kubernetes.cfg

# Args: $1: name
function create_server {
# Creates the machine
echo "Creating $1 with $CPU cpu(s) and $MEMORY MB of RAM"
TEMP_FILE=/tmp/create-vs.out
yes | slcli vs create --hostname $1 --domain $DOMAIN --cpu $CPU --memory $MEMORY --datacenter $DATACENTER --billing hourly --os CENTOS_LATEST > $TEMP_FILE
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
echo Obtaining IP address for $1
get_server_id $1
# Obtain the IP address
slcli vs detail $VS_ID --passwords > $TEMP_FILE
IP_ADDRESS=`grep public_ip $TEMP_FILE | awk '{print $2}'`
}

# From the standpoint of ansible, kube-master-2 is a 'node'
function update_hosts_file {
# Update ansible hosts file
echo Updating ansible hosts files
HOSTS=/tmp/ansible-hosts
echo > $HOSTS
echo "[kube-master]" >> $HOSTS
obtain_ip ${KUBE_MASTER_PREFIX}1
MASTER1_IP=$IP_ADDRESS
echo "kube-master-1 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS

echo "[kube-node]" >> $HOSTS
obtain_ip "${KUBE_NODE_PREFIX}1"
NODE1_IP=$IP_ADDRESS
echo "kube-node-1 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
obtain_ip "${KUBE_NODE_PREFIX}2"
NODE2_IP=$IP_ADDRESS
echo "kube-node-2 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
#obtain_ip ${KUBE_MASTER_PREFIX}2
#MASTER2_IP=$IP_ADDRESS
#echo "kube-master-2 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS

#echo "[secondary-master]" >> $HOSTS
#echo "kube-master-2 ansible_host=$MASTER2_IP ansible_user=root" >> $HOSTS


}

function configure_master {
# Get kube master password
obtain_root_pwd ${KUBE_MASTER_PREFIX}1

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$MASTER1_IP


# Create inventory file
INVENTORY=/tmp/inventory
echo > $INVENTORY
echo "[masters]" >> $INVENTORY
echo "kube-master-1" >> $INVENTORY
#echo "kube-master-2" >> $INVENTORY
echo >> $INVENTORY
echo "[etcd]" >> $INVENTORY
echo "kube-master-1" >> $INVENTORY
#echo "kube-master-2" >> $INVENTORY
echo >> $INVENTORY
echo "[nodes]" >> $INVENTORY
echo "kube-node-1" >> $INVENTORY
echo "kube-node-2" >> $INVENTORY

# Create ansible.cfg
ANSIBLE_CFG=/tmp/ansible.cfg
echo > $ANSIBLE_CFG
echo "[defaults]" >> $ANSIBLE_CFG
echo "host_key_checking = False" >> $ANSIBLE_CFG

# Execute kube-master playbook
ansible-playbook ansible/kube-master.yaml --extra-vars "kube_node1=$NODE1_IP kube_node2=$NODE2_IP"

}

# Args $1 Node name
function configure_node {
echo Configuring node $1

# Get kube master password
obtain_root_pwd $1

# Get master IP address
obtain_ip $1
NODE_IP=$IP_ADDRESS
echo IP Address: $NODE_IP

# Log in to the machine
sshpass -p $PASSWORD ssh-copy-id root@$NODE_IP
}

function configure_nodes {
echo Configuring nodes
configure_node "${KUBE_NODE_PREFIX}1"
configure_node "${KUBE_NODE_PREFIX}2"
#configure_node "${KUBE_MASTER_PREFIX}2"

# Execute kube-master playbook
ansible-playbook ansible/kube-node.yaml
}

function create_nodes {
create_kube "${KUBE_NODE_PREFIX}1"
create_kube "${KUBE_NODE_PREFIX}2"
}

function create_masters {
create_kube "${KUBE_MASTER_PREFIX}1"
#create_kube "${KUBE_MASTER_PREFIX}2"

}

function configure_secondary_master {
# Execute kube-secondary-master playbook
ansible-playbook ansible/kube-secondary-master.yaml --extra-vars "kube_node1=$NODE1_IP kube_node2=$NODE2_IP kube_master1=$MASTER1_IP"
}


# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

create_masters
create_nodes

# Generate SSH key
#yes | ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

update_hosts_file
configure_nodes
#configure_secondary_master
configure_master

echo "Congratulations! You can log on to the kube masters by issuing ssh root@$MASTER1_IP"







