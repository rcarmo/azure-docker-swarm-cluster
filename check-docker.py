from base64 import b64encode
from os.path import exists
from os import environ
from json import dumps
from paramiko import RSAKey, SSHClient, AutoAddPolicy

# Get cluster sizing from environment variables
master_count=int(environ.get('MASTER_COUNT',1))
agent_count=int(environ.get('AGENT_COUNT',2))

master_pattern = "%s-master%d.%s.cloudapp.azure.com"
agent_pattern = "%s-agent-lb.%s.cloudapp.azure.com"


def ssh(address, port=22, username="cluster", key_filename="paramiko.pem"):
    """Returns an open SSH connection"""
    k = RSAKey.from_private_key_file(key_filename)
    c = SSHClient()
    c.set_missing_host_key_policy(AutoAddPolicy()) # automatically add new host keys (use with caution)
    c.connect(address,port=port,username=username,pkey=k)
    return c

def run(session, command):
    """Execute remote command and return output"""
    stdin, stdout, stderr = session.exec_command(command)
    print stderr.read()
    return stdout.read()

# Check if Docker is running on all hosts
for i in range(master_count):
    address = master_pattern % (environ.get('RESOURCE_GROUP'),i,environ.get('LOCATION'))
    s = ssh(address)
    print ">> MASTER %d" % i
    print run(s, "sudo systemctl status docker")

for i in range(agent_count):
    address = agent_pattern % (environ.get('RESOURCE_GROUP'),environ.get('LOCATION'))
    s = ssh(address, port=50000+i)
    print ">> AGENT %d" % i
    print run(s, "sudo systemctl status docker")
