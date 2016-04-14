# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

. ./kubernetes.cfg

# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = https://api.softlayer.com/xmlrpc/v3.1/" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

# Set the server type
if [ $SERVER_TYPE  == "bare" ]; then
  CLI_TYPE=server
else
  CLI_TYPE=vs
fi


# Deletes the kube master
TEMP_FILE=/tmp/destroy_kubernetes.out
slcli $CLI_TYPE list --domain $DOMAIN > $TEMP_FILE
for id in `cat $TEMP_FILE | awk '{print $1}'`
do
   echo Deleting server $id
   echo $id | slcli $CLI_TYPE cancel $id
done





