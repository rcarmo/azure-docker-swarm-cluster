from os import environ
from json import loads, dumps
from utils import master_count, agent_count, master_pattern, agent_pattern, ssh, run

# Obtain Swarm registration tokens
for i in range(1):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    print ">> ", address
    s = ssh("paramiko.pem", address)
    print run(s, "docker swarm init")
    worker_join = ''.join(run(s, "docker swarm join-token worker").replace('\\','').split('\n')[1:])
    master_join = ''.join(run(s, "docker swarm join-token manager").replace('\\','').split('\n')[1:])

# Add masters to cluster
for i in range(1,master_count):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    print ">> MASTER %d" % i, address
    s = ssh("paramiko.pem", address)
    print run(s, master_join)

# Add agents to cluster
for i in range(agent_count):
    address = agent_pattern % (environ.get('RESOURCE_GROUP'),environ.get('LOCATION'))
    s = ssh("paramiko.pem", address, port=50000+i)
    print ">> AGENT %d" % i, address
    print run(s, worker_join)
   
# Check status and install a Swarm visualizer on port 8080 of master0 (this is just a nicer way to see swarm status, and isn't really part of the solution')
for i in range(1):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    print ">> ", address
    s = ssh("paramiko.pem", address)
    print run(s, "docker info | grep Swarm -A 5")
    print run(s, "docker run -it -d -p 8080:8080 -e HOST=%s -v /var/run/docker.sock:/var/run/docker.sock manomarks/visualizer" % address)
