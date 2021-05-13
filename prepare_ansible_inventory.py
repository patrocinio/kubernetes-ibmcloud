import json

HOSTS = "/tmp/ansible-hosts"

file = open('terraform_show.json')
show = json.load(file)

f = open(HOSTS, "w")

# List the master nodes
ips =  show['values']['outputs']['masters']['value']['floating_ips']

f.write("[first-kube-master]\n")
f.write("%s ansible_host=%s ansible_user=root\n" % (ips[0]['name'], ips[0]['address']))
f.write("\n");

f.write("[other-kube-masters]\n")
for i in range(1, len(ips)):
    f.write("%s ansible_host=%s ansible_user=root\n" % (ips[i]['name'], ips[i]['address']))
f.write("\n");

# List the workers
ips =  show['values']['outputs']['workers']['value']['floating_ips']

f.write("[workers]\n")
for i in range(0, len(ips)):
    f.write("%s ansible_host=%s ansible_user=root\n" % (ips[i]['name'], ips[i]['address']))


f.close()

