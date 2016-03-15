Deploy a Kubernetes environment in SoftLayer with a single command! It's that simple.

Follow this procedure:

1. First clone this project
2. Edit the kubernetes.cfg file to enter the following SoftLayer configuration
   * USER
   * API_KEY
* (Optional) DATACENTER: Check http://www.softlayer.com/data-centers and look at the Ping/Trace Route column for the code. For example, the code for speedtest.wdc01.softlayer.com is wdc01
3. Run the following command:
`deploy-kubernetes.sh`

Simple, no?

Take a look at the following scripts too:

* `display-kubernetes.sh`
* `destroy-kubernetes.sh`
* `remove_api_key.sh`
