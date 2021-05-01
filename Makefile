SHELL := /bin/bash

HOSTS := /tmp/ansible-hosts
TEMP_FILE := /tmp/ansible-line

ifndef RESOURCE_PREFIX
$(error RESOURCE_PREFIX is not set, please read the README and set using .envrc.)
endif

ifndef IC_API_KEY
$(error IC_API_KEY is not set, please read the README and set using .envrc.)
endif

.PHONY: all

install:
	ibmcloud plugin install container-registry
	ibmcloud plugin install container-service
	ibmcloud plugin install observe-service
	ibmcloud plugin install vpc-infrastructure

watch:
	./watch_ibmcloud $(RESOURCE_PREFIX)

terraform_init:
ifeq (, $(shell which tfswitch))
	(cd terraform && terraform init)
else
	(cd terraform && tfswitch && terraform init)
endif

perform_clean: login_ibmcloud
	cd terraform && terraform destroy -auto-approve

check_clean:
	@echo -n "Are you sure you want to delete all resources? [y/N] " && read ans && [ $${ans:-N} = y ]

aggressive_clean: check_clean
	until make perform_clean; do echo 'Retrying clean...'; sleep 10; done

clean: check_clean terraform_init
	make perform_clean

ssh-keygen:
	mkdir -p ssh-keys/
	ssh-keygen -f ssh-keys/ssh-key
	chmod 600 ssh
	cat ssh-keys/ssh-key.pub | cut -d' ' -f2 | sed 's/^/export TF_VAR_SSH_PUBLIC_KEY="/' | sed 's/$$/"/' >> ./.envrc

login_ibmcloud:
	# For now, we forcibly select us-east from this list: https://cloud.ibm.com/docs/satellite?topic=satellite-sat-regions.
	ibmcloud login --apikey $(IC_API_KEY) -r us-east

target_resource_group:
	ibmcloud target -g $(RESOURCE_PREFIX)-group

apply_terraform: terraform_init
	echo RESOURCE_PREFIX: $(RESOURCE_PREFIX)
	echo NUM_MASTERS: $(TF_VAR_NUM_MASTERS)
	echo NUM_WORKERS: $(TF_VAR_NUM_WORKERS)
	(cd terraform && terraform apply -auto-approve)

get_terraform_show:
	(cd terraform && terraform show -json > ../terraform_show.json)

prep_ansible_inventory: get_terraform_show
	python prepare_ansible_inventory.py

first_master: prep_ansible_inventory 
	(cd ansible && ansible-playbook -v -i $(HOSTS) kube-first-master.yaml -e "lb_hostname=$(shell cd terraform && terraform output lb_hostname | tr -d '"')"  --key-file "../ssh-keys/ssh-key")

kube_ui:  
	kubectl apply -f kube_resources/kube_ui_service_account.yaml 
	kubectl apply -f kube_resources/kube_ui_cluster_role_binding.yaml 
	kubectl delete svc kubernetes-bashboard
	kubectl apply -f kube_resources/kube_ui_svc.yaml
	kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"

config_kubectl:  
	(cd ansible && ansible-playbook -v -i $(HOSTS) configure-kubectl.yaml -e "lb_hostname=$(shell cd terraform && terraform output lb_hostname | tr -d '"')"  --key-file "../ssh-keys/ssh-key")

create_join_stmt: 
	(cd ansible && ansible-playbook -v -i $(HOSTS) create-token.yaml  --key-file "../ssh-keys/ssh-key")

apply_other_masters: prep_ansible_inventory
	(cd ansible && ansible-playbook -v -i $(HOSTS) kube-other-masters.yaml --key-file "../ssh-keys/ssh-key" -e "join='$(shell cat /tmp/join)'")

first_etcdadm:
	(cd ansible && ansible-playbook -v -i $(HOSTS) first-etcdadm.yaml  --key-file "../ssh-keys/ssh-key")

other_etcds:
	(cd ansible && ansible-playbook -v -i $(HOSTS) other-etcds.yaml  --key-file "../ssh-keys/ssh-key" -e "lb_hostname=$(shell cd terraform && terraform output first_master_ip | tr -d '"')")

apply_ansible: first_etcdadm first_master kube_ui config_kubectl create_join_stmt apply_other_masters

kube_reset:
	(cd ansible && ansible-playbook -v -i $(HOSTS) kube-reset.yaml --key-file "../ssh-keys/ssh-key")

ssh_master:
	ssh -i ssh-keys/ssh-key root@$(shell ./retrieve_master_ip.sh)

terraform_refresh:
	(cd terraform && terraform refresh)

all: login_ibmcloud
	date
	make apply_terraform
	date
	make apply_ansible
	date
	echo "Done!"
