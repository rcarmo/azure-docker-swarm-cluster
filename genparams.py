from base64 import b64encode
from os import environ
from json import dumps
from utils import make_key

make_key("paramiko.pem")

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
