SHELL := /bin/bash

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
	cat ssh-keys/ssh-key.pub | cut -d' ' -f2 | sed 's/^/export TF_VAR_SSH_PUBLIC_KEY="/' | sed 's/$$/"/' >> ./.envrc 

login_ibmcloud:
	# For now, we forcibly select us-east from this list: https://cloud.ibm.com/docs/satellite?topic=satellite-sat-regions.
	ibmcloud login --apikey $(IC_API_KEY) -r us-east

target_resource_group:
	ibmcloud target -g $(RESOURCE_PREFIX)-group

apply_terraform: terraform_init
	(cd terraform && terraform apply -auto-approve)

get_terraform_show:
	(cd terraform && terraform show -json > ../terraform_show.json)

prep_ansible_inventory: get_terraform_show
	cat terraform_show.json | jq --raw-output .values.outputs.ipaddress_controlplane01_floating.value,.values.outputs.ipaddress_controlplane02_floating.value,.values.outputs.ipaddress_controlplane03_floating.value,.values.outputs.ipaddress_workernode01_floating.value,.values.outputs.ipaddress_workernode02_floating.value,.values.outputs.ipaddress_workernode03_floating.value > ansible/.inventory
	paste -d ' ' ansible/.inventory ansible/inventory_postfix > ansible/inventory
	rm ansible/.inventory

apply_ansible: prep_ansible_inventory attach_host
	(cd ansible && ansible-playbook install-machine.yml -i inventory)

all: login_ibmcloud
	date
	make ssh-keygen
	date
	make apply_terraform 
	date
	make apply_ansible
	date
	echo "Done!"
