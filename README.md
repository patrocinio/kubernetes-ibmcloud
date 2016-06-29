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
2. Edit the kubernetes.cfg file to enter the following SoftLayer configuration
3. Mandatory fields:
   * USER
   * API_KEY: Check https://knowledgelayer.softlayer.com/procedure/generate-api-key to see how you can generate an API key
* Optional ones:
   * DATACENTER: Run the following command to obtain the data center code: `slcli vs create-options | grep datacenter`
   * DOMAIN: hostname domain
   * SERVER_TYPE: bare for bare metal; anything else for virtual servers
   * For virtual servers:
	   * CPU: Define the number of CPIUs you want in each server
   		* MEMORY: Define the amount of RAM (in MB) in each server
   * For bare metal:
   		* SIZE: Run `slcli server create-options` for values
   * PUBLIC_VLAN: Define the public VLAN number
   * PRIVATE_VLAN: Define the private VLAN number

3. Run the following command:
`deploy-kubernetes.sh`

Simple, no?

## Testing the environment

We recommend running the Guestbook application to test your environment.
Log on to the kube master and follow these steps:

    mkdir guestbook
    cd guestbook
    git clone https://github.com/kubernetes/kubernetes.git
    cd kubernetes
    git reset --hard 6a657e0bc25eafd44fa042b079c36f8f0413d420
    kubectl create -f examples/guestbook/all-in-one/guestbook-all-in-one.yaml

You can monitor the progress of the deployment by typing the following command:

    kubectl get pods

After a few seconds (or minutes), you should see the following result:

    [root@kube-master-1 guestbook]# kubectl get pods
    NAME                 READY     STATUS    RESTARTS   AGE
    frontend-3ibiv       1/1       Running   0          15m
    frontend-yg8ci       1/1       Running   0          15m
    frontend-yj0ca       1/1       Running   0          15m
    redis-master-p8tqa   1/1       Running   0          15m
    redis-slave-c0ydz    1/1       Running   0          15m
    redis-slave-erlp0    1/1       Running   0          15m

## Other scripts

Take a look at the following scripts too:

* `display-kubernetes.sh`
* `destroy-kubernetes.sh`
* `remove_api_key.sh`

### Reference links
* [Disabling GNOME Keyring](https://chrisjean.com/ubuntu-ssh-fix-for-agent-admitted-failure-to-sign-using-the-key/) - Causes interference with some SSH-based actions
* [sshpass man page](http://manpages.ubuntu.com/manpages/trusty/man1/sshpass.1.html)
* [sshpass return code 6](http://stackoverflow.com/questions/33961214/docker-run-fails-with-returned-a-non-zero-code-6) - When host key checking causes errors in SSH scripting
