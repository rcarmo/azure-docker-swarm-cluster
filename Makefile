# Set environment variables (if they're not defined yet)
export RESOURCE_GROUP?=swarm-demo
export LOCATION?=northeurope
export MASTER_COUNT?=1
export AGENT_COUNT?=3
export MASTER_FQDN=$(RESOURCE_GROUP)-master0.$(LOCATION).cloudapp.azure.com
export VMSS_NAME=agents

SSH_KEY_FILES := cluster.pem cluster.pub
PARAMETER_FILES := parameters-masters.json parameters-agents.json

# dump resource groups
resources:
	az group list --output table

# Dump list of location IDs
locations:
	az account list-locations --output table

# Generate SSH keys for the cluster
keys:
	ssh-keygen -b 2048 -t rsa -f cluster -q -N ""
	mv cluster cluster.pem


# Generate the Azure Resource Template parameter files
params: $(SSH_KEY_FILES) cloud-config-master.yml cloud-config-agent.yml
	python genparams.py


# Destroy the entire resource group and all cluster resources
destroy-cluster:
	az group delete --name $(RESOURCE_GROUP)


# Create a resource group and deploy the cluster resources inside it
deploy-cluster:
	-az group create --name $(RESOURCE_GROUP) --location $(LOCATION) --output table 
	az group deployment create --template-file cluster-template.json --parameters @parameters.json --resource-group $(RESOURCE_GROUP) --name cli-deployment-$(LOCATION) --output table

# Cleanup parameters
clean:
	rm -f cluster.pem cluster.pub parameters.json

# Deploy the Swarm monitor
deploy-monitor:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker run -it -d -p 8080:8080 -e HOST=$(MASTER_FQDN) -v /var/run/docker.sock:/var/run/docker.sock manomarks/visualizer 

# Kill the swarm monitor
kill-monitor:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	"docker ps | grep manomarks/visualizer | cut -d\  -f 1 | xargs docker kill"

# Deploy the replicated service
deploy-replicated-service:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service create --name replicated --publish 80:8000 \
	--replicas=8 --env SWARM_MODE="REPLICATED" --env SWARM_PUBLIC_PORT=80 \
	rcarmo/demo-frontend-stateless

# Deploy the global service
deploy-global-service:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service create --name global --publish 81:8000 \
	--mode global --env SWARM_MODE="GLOBAL" --env SWARM_PUBLIC_PORT=81 \
	rcarmo/demo-frontend-stateless

# Scale the demo service
scale-service-%:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service scale replicated=$*

# Update the service (rebalancing doesn't work yet)
update-service:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) \
	docker service update replcated

# SSH to master node
ssh-master:
	ssh -A -i cluster.pem cluster@$(MASTER_FQDN) \
	-L 9080:localhost:80 \
	-L 9081:localhost:81 \
	-L 8080:localhost:8080 \
	-L 4040:localhost:4040

# Show swarm helper log
tail-helper:
	ssh -i cluster.pem cluster@$(MASTER_FQDN) sudo journalctl -f -u swarm-helper

# List VMSS instances
list-vmss:
	az vmss list-instances --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 

# Scale VMSS instances
scale-vmss-%:
	az vmss scale --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --new-capacity $* --output table 

# Stop all VMSS instances
stop-vmss:
	az vmss stop --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 

# Start all VMSS instances
start-vmss:
	az vmss start --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --output table 

# List endpoints
list-endpoints:
	az network public-ip list --query '[].{dnsSettings:dnsSettings.fqdn}' --resource-group $(RESOURCE_GROUP) --output table
