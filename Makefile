# Set environment variables (if they're not defined yet)
export RESOURCE_GROUP?=swarm-test
export LOCATION?=westeurope
# This lets us run this scenario under Cygwin
export AZURE_CLI?=azure.cmd
export MASTER_COUNT?=3
export AGENT_COUNT?=5

# Generate the Azure Resource Template parameter file
params:
	python genparams.py 
	cat parameters.json

# Destroy the entire resource group and all cluster resources
destroy:
	$(AZURE_CLI) group delete $(RESOURCE_GROUP)

# Create a resource group and deploy the cluster resources inside it
deploy:
	$(AZURE_CLI) group create $(RESOURCE_GROUP) $(LOCATION)
	$(AZURE_CLI) group deployment create -f swarm-cluster.json -e parameters.json -g $(RESOURCE_GROUP)

# Check on deployment progress
check-deploy:
	$(AZURE_CLI) group deployment list $(RESOURCE_GROUP)

# Check Docker daemon status across nodes
check-docker:
	python check-docker.py

# Provision the Swarm cluster by initializing it and distributing master and agent tokens
provision-cluster:
	python provision-cluster.py

# Provision a simple test service on every node in the cluster
provision-service:
	python provision-service.py

# Dump the public IP addresses in use
ips:
	$(AZURE_CLI) network public-ip list

# Dump the DNS aliases that were provisioned (requires jq)
names:
	$(AZURE_CLI) network public-ip list --json | jq ".[] | .dnsSettings.fqdn"
