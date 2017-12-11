# Set environment variables
export RESOURCE_GROUP?=swarm-cluster
export LOCATION?=eastus
export MASTER_COUNT?=1
export AGENT_COUNT?=3
export MASTER_FQDN=$(RESOURCE_GROUP)-master0.$(LOCATION).cloudapp.azure.com
export LOADBALANCER_FQDN=$(RESOURCE_GROUP)-agents-lb.$(LOCATION).cloudapp.azure.com
export VMSS_NAME=agents
export ADMIN_USERNAME?=cluster
export TIMESTAMP=`date "+%Y-%m-%d-%H-%M-%S"`

# Permanent local overrides
-include .env

SSH_KEY_FILES:=$(ADMIN_USERNAME).pem $(ADMIN_USERNAME).pub
SSH_KEY:=$(ADMIN_USERNAME).pem

# Do not output warnings, do not validate or add remote host keys (useful when doing successive deployments or going through the load balancer)
SSH_TO_MASTER:=ssh -q -A -i keys/$(SSH_KEY) $(ADMIN_USERNAME)@$(MASTER_FQDN) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

# dump resource groups
resources:
	az group list --output table

# Dump list of location IDs
locations:
	az account list-locations --output table

# Generate SSH keys for the cluster (optional)
keys:
	mkdir keys
	ssh-keygen -b 2048 -t rsa -f keys/$(ADMIN_USERNAME) -q -N ""
	mv keys/$(ADMIN_USERNAME) keys/$(ADMIN_USERNAME).pem

# Generate the Azure Resource Template parameter files
params:
	@mkdir parameters 2> /dev/null; python genparams.py > parameters/cluster.json

# Cleanup parameters
clean:
	rm -rf parameters

# Create a resource group and deploy the cluster resources inside it
deploy-cluster:
	-az group create --name $(RESOURCE_GROUP) --location $(LOCATION) --output table 
	az group deployment create \
		--template-file templates/cluster.json \
		--parameters @parameters/cluster.json \
		--resource-group $(RESOURCE_GROUP) \
		--name cli-$(LOCATION) \
		--output table \
		--no-wait

# Destroy the entire resource group and all cluster resources
destroy-cluster:
	az group delete \
		--name $(RESOURCE_GROUP) \
		--no-wait

# Deploy the Swarm monitor
deploy-monitor:
	$(SSH_TO_MASTER) \
	docker run -it -d -p 8080:8080 \
		-e HOST=$(MASTER_FQDN) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		dockersamples/visualizer

# Kill the swarm monitor
kill-monitor:
	$(SSH_TO_MASTER) \
	"docker ps | grep dockersamples/visualizer | cut -d\  -f 1 | xargs docker kill"

# Deploy the replicated service
deploy-replicated-service:
	$(SSH_TO_MASTER) \
	docker service create \
		--name replicated \
		--publish 80:8000 \
		--replicas=8 \
		--env SWARM_MODE="REPLICATED" \
		--env SWARM_PUBLIC_PORT=80 \
		rcarmo/demo-frontend

# Deploy the global service
deploy-global-service:
	$(SSH_TO_MASTER) \
	docker service create \
		--name global \
		--publish 81:8000 \
		--mode global \
		--env SWARM_MODE="GLOBAL" \
		--env SWARM_PUBLIC_PORT=81 \
		rcarmo/demo-frontend

# Destroy the global service
destroy-global-service:
	$(SSH_TO_MASTER) \
	docker service rm global

# Deploy the test stack
deploy-stack:
	cat test-stack/docker-compose.yml | $(SSH_TO_MASTER) "tee > ~/docker-compose.yml"
	$(SSH_TO_MASTER) "docker stack deploy -c ~/docker-compose.yml test-stack"

destroy-stack:
	$(SSH_TO_MASTER) docker stack rm test-stack


deploy-weavescope:
	$(SSH_TO_MASTER) "curl -L git.io/scope -o ~/scope && chmod a+x ~/scope && ~/scope launch"

# Scale the demo service
scale-service-20:
	$(SSH_TO_MASTER) \
	docker service scale replicated=20

scale-service-%:
	$(SSH_TO_MASTER) \
	docker service scale replicated=$*

# Destroy the global service
destroy-service:
	$(SSH_TO_MASTER) \
	docker service rm replicated

# Update the service (rebalancing doesn't work yet)
update-service:
	$(SSH_TO_MASTER) \
	docker service update replicated

# SSH to master node
proxy:
	$(SSH_TO_MASTER) \
	-L 9080:localhost:80 \
	-L 9081:localhost:81 \
	-L 8080:localhost:8080 \
	-L 4040:localhost:4040

# Show swarm helper log
tail-helper:
	$(SSH_TO_MASTER) \
	sudo journalctl -f -u swarm-helper

# View deployment details
view-deployment:
	az group deployment operation list \
		--resource-group $(RESOURCE_GROUP) \
		--name cli-$(LOCATION) \
		--query "[].{OperationID:operationId,Name:properties.targetResource.resourceName,Type:properties.targetResource.resourceType,State:properties.provisioningState,Status:properties.statusCode}" \
		--output table

# List VMSS instances
list-agents:
	az vmss list-instances \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--output table 

# Scale VMSS instances
scale-agents-%:
	az vmss scale \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--new-capacity $* \
		--output table \
		--no-wait

# Stop all VMSS instances
stop-agents:
	az vmss stop \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--no-wait

# Start all VMSS instances
start-agents:
	az vmss start \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--no-wait

# Reimage VMSS instances
reimage-agents-parallel:
	az vmss reimage --resource-group $(RESOURCE_GROUP) --name $(VMSS_NAME) --no-wait

reimage-agents-serial:
	az vmss list-instances \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--query [].instanceId \
		--output tsv \
	| xargs -I{} az vmss reimage \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--instance-id {} \
		--output table

chaos-monkey:
	az vmss list-instances \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--query [].instanceId \
		--output tsv \
	| shuf \
	| xargs -I{} az vmss restart \
		--resource-group $(RESOURCE_GROUP) \
		--name $(VMSS_NAME) \
		--instance-id {} \
		--output table

# List endpoints
list-endpoints:
	az network public-ip list \
		--resource-group $(RESOURCE_GROUP) \
		--query '[].{dnsSettings:dnsSettings.fqdn}' \
		--output table
