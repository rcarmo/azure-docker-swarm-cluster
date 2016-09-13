from os import environ
from json import loads, dumps
from utils import master_count, agent_count, master_pattern, agent_pattern, ssh, run

# Provision a simple service (on port 80 of _every_ node) to test Swarm IPVS load balancing
for i in range(1):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    print ">> ", address
    s = ssh("paramiko.pem", address)
    print run(s, "docker service create --name demo --replicas=4 --publish 80:8000 rcarmo/demo-frontend-stateless")

