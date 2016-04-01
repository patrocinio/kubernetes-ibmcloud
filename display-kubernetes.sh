# Installs the SoftLayer CLI
#pip install --upgrade pip
#pip install softlayer

. ./kubernetes.cfg

# Authenticates to SL
echo "[softlayer]" > ~/.softlayer
echo "username = $USER" >> ~/.softlayer
echo "api_key = $API_KEY" >> ~/.softlayer
echo "endpoint_url = $ENDPOINT" >> ~/.softlayer
echo "timeout = 0" >> ~/.softlayer

echo Using the following SoftLayer configuration
slcli config show

# Set the server type
if [ $SERVER_TYPE  == "bare" ]; then
  CLI_TYPE=server
else
  CLI_TYPE=vs
fi


# Creates the kube master
slcli $CLI_TYPE list --domain $DOMAIN






