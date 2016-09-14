from os import environ
from utils import master_count, agent_count, master_pattern, agent_pattern, ssh, run

# Check if Docker is running on all hosts
for i in range(master_count):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    s = ssh("paramiko.pem", address)
    print ">> MASTER %d" % i, address
    print run(s, "sudo systemctl status docker")

for i in range(agent_count):
    address = agent_pattern % (environ.get('RESOURCE_GROUP'),environ.get('LOCATION'))
    s = ssh("paramiko.pem", address, port=50000+i)
    print ">> AGENT %d" % i, address, port
    print run(s, "sudo systemctl status docker")
   
