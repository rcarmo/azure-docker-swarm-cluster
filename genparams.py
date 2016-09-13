from base64 import b64encode
from os.path import exists
from os import environ
from json import dumps

# Generate a passwordless key for automation
if not exists("paramiko.pem"):
    from paramiko import SSHClient, AutoAddPolicy, RSAKey
    from StringIO import StringIO
    k = RSAKey.generate(1024)
    k.write_private_key_file("paramiko.pem")
    with open("paramiko.pub", 'w') as f:
        f.write("%s %s" % (k.get_name(), k.get_base64()))


# Build the ARM template parameters, bringing in evironment variables for sizing
params = {
    "adminUsername": {
        "value": "cluster"
    },
    "masterCount": {
        "value": int(environ.get('MASTER_COUNT',1))
    },
    "agentCount": {
        "value": int(environ.get('AGENT_COUNT',2))
    },
    "customData": {
        # Build a cloud-init configuration that:
        # - Adds the official Docker repository to Ubuntu
        # - Installs the Docker engine and a few extras (including an updated kernel)
        # - Cleans up and reboots the machine
        "value": b64encode("""#cloud-config
runcmd:
    - apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    - echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
    - apt-get update
    - apt-get install -y docker-engine tmux htop vim fail2ban curl
    - usermod -G docker cluster
    - systemctl start docker
    - systemctl enable docker
    - apt-get dist-upgrade -y
    - apt-get autoremove -y
    - reboot
""")
    },
    "adminPublicKey": {
        "value": open("paramiko.pub","r").read()
    }
}

with open('parameters.json', 'w') as h:
    h.write(dumps(params))