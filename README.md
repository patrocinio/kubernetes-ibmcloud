## Deploy a Kubernetes environment in SoftLayer with a single command! It's that simple.

### Prerequisites:
1. PIP - `sudo apt-get install python-pip python-dev build-essential`
2. SoftLayer CLI - `sudo pip install --upgrade pip softlayer`
3. Ansible v2.0 or newer- `sudo apt-get install ansible`
4. sshpass - `sudo apt-get install sshpass`
5. A default SSH key must exist on your local platform.  If one does not exist, this can be created via the command `ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa`.

NOTE:  If you encounter SSH issues running from Ubuntu, install `sudo pip install requests[security]` first.  If that does not eliminate the issue, you may be hitting an issue with GNOME Keyring.  See [this article](https://chrisjean.com/ubuntu-ssh-fix-for-agent-admitted-failure-to-sign-using-the-key/) for a fix.

### Deployment:
Follow this procedure:

1. First clone this project: `git clone https://github.com/patrocinio/kubernetes-softlayer.git`
2. Copy the file .envrc-template as .envrc: `cp .envrc-template .envrc`
3. Mandatory fields:
   * RESOURCE_PREFIX
   * API_KEY: Check https://cloud.ibm.com/docs/account?topic=account-userapikey#create_user_key to see how you can generate an API key
4. Optional ones:
   * TF_VAR_NUM_WORKERS: The number of worker nodes
   * TF_VAR_NUM_MASTERS: The number of master nodes 
   * KUBELET_PORT_NUMBER: The port number that kubelet is listening (default is 10250)
   * TF_VAR_CLOUD_REGION: The IBM Cloud region where the cluster is deployed 
5. Load the file in the current shell:`. ./.envrc`
5. Run the following command:`make all`

Simple, no?

The process will go through a few phases:
- It creates the cloud resources, using Terraform
- It configures the virtual machines, using Ansible


