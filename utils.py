from base64 import b64encode
from os.path import exists, splitext
from os import environ
from json import dumps, loads
from paramiko import RSAKey, SSHClient, AutoAddPolicy
from StringIO import StringIO

# Get cluster sizing from environment variables
master_count=int(environ.get('MASTER_COUNT',1))
agent_count=int(environ.get('AGENT_COUNT',2))

# Define FQDN patterns that match the template's
master_pattern = "%s-master%d.%s.cloudapp.azure.com"
agent_pattern = "%s-agent-lb.%s.cloudapp.azure.com"

# Create a passwordless SSH key for provisioning
def make_key(filename="paramiko.pem"):
    if not exists(filename):
        k = RSAKey.generate(1024)
        k.write_private_key_file(filename)
        with open(splitext(filename)[0]+'.pub', 'w') as f:
            f.write("%s %s" % (k.get_name(), k.get_base64()))

# Build and return an SSH session
def ssh(filename, address, port=22, username="cluster"):
    k = RSAKey.from_private_key_file(filename)
    c = SSHClient()
    c.set_missing_host_key_policy(AutoAddPolicy())
    c.connect(address,port=port,username=username,pkey=k)
    return c

# Run a remote command via SSH
def run(session, command):
    stdin, stdout, stderr = session.exec_command(command)
    print stderr.read()
    return stdout.read()
