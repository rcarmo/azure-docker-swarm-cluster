# Set environment variables (if they're not defined yet)
export RESOURCE_GROUP?=swarm-demo
export LOCATION?=northeurope
export AZURE_CLI?=az
export MASTER_COUNT?=1
export AGENT_COUNT?=3
export MASTER_FQDN=$(RESOURCE_GROUP)-master0.$(LOCATION).cloudapp.azure.com
export VMSS_NAME=agent

SSH_KEY_FILES := cluster.pem cluster.pub
PARAMETER_FILES := parameters-masters.json parameters-agents.json

# Generate SSH keys for the cluster
keys:
	ssh-keygen -b 2048 -t rsa -f cluster -q -N ""
	mv cluster cluster.pem


# Generate the Azure Resource Template parameter files
params: $(SSH_KEY_FILES) cloud-config-master.yml cloud-config-agent.yml
	python genparams.py


# Destroy the entire resource group and all cluster resources
destroy:
	$(AZURE_CLI) resource group delete --name $(RESOURCE_GROUP)


# Create a resource group and deploy the cluster resources inside it
deploy:
	-$(AZURE_CLI) resource group create --name $(RESOURCE_GROUP) --location $(LOCATION) --output table 
	$(AZURE_CLI) resource group deployment create --template-file-path cluster-template.json --parameters-file-path parameters.json --resource-group $(RESOURCE_GROUP) --name cli-deployment-$(LOCATION) --output table


clean:
	rm -f cluster.pem cluster.pub parameters.json


deploy-monitor:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker run -it -d -p 8080:8080 -e HOST=$(MASTER_FQDN) -v /var/run/docker.sock:/var/run/docker.sock manomarks/visualizer 


deploy-service:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service create --name demo --replicas=8 --publish 80:8000 rcarmo/demo-frontend-stateless


scale-service-%:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service scale demo=$*


update-service:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service update demo

ssh-master:
	ssh-add cluster.pem
	ssh -A -i cluster.pem cluster@$(MASTER_FQDN)


tail-helper:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) sudo journalctl -f -u swarm-helper


scale-%:
	$(AZURE_CLI) vmss scale --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --new-capacity $* --output table 


stop:
	$(AZURE_CLI) vmss stop --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 


start:
	$(AZURE_CLI) vmss start --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 


list:
	$(AZURE_CLI) vmss list-instances --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 


endpoints:
	$(AZURE_CLI) network public-ip list --query '[].{dnsSettings:dnsSettings.fqdn}' --resource-group $(RESOURCE_GROUP) --output table
