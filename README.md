## Deploy a Kubernetes environment in SoftLayer with a single command! It's that simple.

Follow this procedure:

1. First clone this project
2. Edit the kubernetes.cfg file to enter the following SoftLayer configuration
   * USER
   * API_KEY
   * (Optional) DATACENTER: Check http://www.softlayer.com/data-centers and look at the Ping/Trace Route column for the code. For example, the code for speedtest.wdc01.softlayer.com is wdc01
   * (Optional) CPU: Define the number of CPIUs you want in each server
   * (Optional) MEMORY: Define the amount of RAM (in MB) in each server
   * (Optional) PUBLIC_VLAN: Define the public VLAN number
   * (Optional) PRIVATE_VLAN: Define the private VLAN number

3. Run the following command:
`deploy-kubernetes.sh`

Simple, no?

## Testing the environment 

We recommend running the Guestbook application to test your environment.
Log on to the kube master and follow these steps:

    mkdir guestbook
    cd guestbook
    git clone https://github.com/kubernetes/kubernetes.git
    kubectl create -f kubernetes/examples/guestbook/all-in-one/guestbook-all-in-one.yaml

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
