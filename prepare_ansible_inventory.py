import json

HOSTS = "/tmp/ansible-hosts"

file = open('terraform_show.json')
show = json.load(file)

ips =  show['values']['outputs']['masters']['value']['floating_ips']

f = open(HOSTS, "w")

f.write("[first-kube-master]\n")
f.write("%s ansible_host=%s ansible_user=root\n" % (ips[0]['name'], ips[0]['address']))
f.write("\n");

f.write("[other-kube-masters]\n")
for i in range(1, len(ips)):
    f.write("%s ansible_host=%s ansible_user=root\n" % (ips[i]['name'], ips[i]['address']))

f.close()

