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
	echo NUM_MASTERS: $(NUM_MASTERS)
	(cd terraform && terraform apply -auto-approve)

get_terraform_show:
	(cd terraform && terraform show -json > ../terraform_show.json)

prep_ansible_inventory: get_terraform_show
	echo > $(HOSTS)
	echo "[kube-master] " >> $(HOSTS)
	echo "kube-master-1 " >> $(TEMP_FILE)
	echo "ansible_host=" >> $(TEMP_FILE)
	cat terraform_show.json | jq --raw-output .values.outputs.ipaddress_master01_floating.value >> $(TEMP_FILE)
	echo " ansible_user=root" >> $(TEMP_FILE)
	paste -s -d '\0' $(TEMP_FILE) >> $(HOSTS)
	rm $(TEMP_FILE)

apply_ansible: prep_ansible_inventory
	echo Master IP: $(shell cd terraform && terraform output ipaddress_master01_private | tr -d '"')
	(cd ansible && ansible-playbook -v -i $(HOSTS) kube-master.yaml -e "master_private_ip=$(shell cd terraform && terraform output ipaddress_master01_private | tr -d '"')" --key-file "../ssh-keys/ssh-key")

kube_reset:
	(cd ansible && ansible-playbook -v -i $(HOSTS) kube-reset.yaml --key-file "../ssh-keys/ssh-key")


all: login_ibmcloud
	date
	make apply_terraform
	date
	make apply_ansible
	date
	echo "Done!"
