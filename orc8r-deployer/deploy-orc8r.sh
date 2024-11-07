#!/usr/bin/env bash

set -e

# Check if the system is Linux
if [ $(uname) != "Linux" ]; then
  echo "This script is only for Linux"
  exit 1
fi

# Run as root user
if [ $(id -u) != 0 ]; then
  echo "Please run as root user"
  exit 1
fi

DEFAULT_ORC8R_DOMAIN="magma.local"
DEFAULT_NMS_ORGANIZATION_NAME="magma-test"
DEFAULT_NMS_EMAIL_ID_AND_PASSWORD="admin"
DEFAULT_DEPLOYER_PATH="$1"
ORC8R_IP=$(hostname -I | awk '{print $1}')
GITHUB_USERNAME="magma"
MAGMA_DOCKER_REGISTRY="magmacore"
MAGMA_ORC8R_REPO="magma-deployer"
MAGMA_USER="magma"
HOSTS_FILE="hosts.yml"

# Take input from user
read -p "Your Magma Orchestrator domain name? [${DEFAULT_ORC8R_DOMAIN}]: " ORC8R_DOMAIN
ORC8R_DOMAIN="${ORC8R_DOMAIN:-${DEFAULT_ORC8R_DOMAIN}}"

read -p "NMS organization(subdomain) name you want? [${DEFAULT_NMS_ORGANIZATION_NAME}]: " NMS_ORGANIZATION_NAME
NMS_ORGANIZATION_NAME="${NMS_ORGANIZATION_NAME:-${DEFAULT_NMS_ORGANIZATION_NAME}}"

read -p "Set your email ID for NMS? [${DEFAULT_NMS_EMAIL_ID_AND_PASSWORD}]: " NMS_EMAIL_ID
NMS_EMAIL_ID="${NMS_EMAIL_ID:-${DEFAULT_NMS_EMAIL_ID_AND_PASSWORD}}"

read -p "Set your password for NMS? [${DEFAULT_NMS_EMAIL_ID_AND_PASSWORD}]: " NMS_PASSWORD
NMS_PASSWORD="${NMS_PASSWORD:-${DEFAULT_NMS_EMAIL_ID_AND_PASSWORD}}"

read -p "If you've already cloned magma-deployer, enter the path here: [${DEFAULT_DEPLOYER_PATH}]: " DEPLOYER_PATH
DEPLOYER_PATH="${DEPLOYER_PATH:-${DEFAULT_DEPLOYER_PATH}}"

test -d ${DEPLOYER_PATH} && cp -pvr ${DEPLOYER_PATH} /tmp/magma-deployer/

# Add repos for installing yq and ansible
ls /etc/apt/sources.list.d|grep yq || add-apt-repository --yes ppa:rmescandon/yq
ls /etc/apt/sources.list.d|grep ansible || add-apt-repository --yes ppa:ansible/ansible

# Install yq and ansible
which yq || apt install yq -y
which ansible || apt install ansible -y

# Create magma user and give sudo permissions
id ${MAGMA_USER} || useradd -m ${MAGMA_USER} -s /bin/bash -G sudo
grep ${MAGMA_USER} /etc/sudoers || echo "${MAGMA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# switch to magma user
su - ${MAGMA_USER} -c bash <<_

# Genereta SSH key for magma user
test -f ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
test -f ~/.ssh/authorized_keys || cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys 

if test -d /tmp/magma-deployer
then
	cp -pvr /tmp/magma-deployer ~/
else
	# Clone Magma Deployer repo
	echo git clone https://github.com/${GITHUB_USERNAME}/${MAGMA_ORC8R_REPO} --depth 1
fi

cd ~/${MAGMA_ORC8R_REPO}

# export variables for yq
export ORC8R_IP=${ORC8R_IP}
export MAGMA_USER=${MAGMA_USER}
export ORC8R_DOMAIN=${ORC8R_DOMAIN}
export NMS_ORGANIZATION_NAME=${NMS_ORGANIZATION_NAME}
export NMS_EMAIL_ID=${NMS_EMAIL_ID}
export NMS_PASSWORD=${NMS_PASSWORD}

# Update values to the config file
yq e '.all.hosts = env(ORC8R_IP)' -i ${HOSTS_FILE}
yq e '.all.vars.ansible_user = env(MAGMA_USER)' -i ${HOSTS_FILE}
yq e '.all.vars.orc8r_domain = env(ORC8R_DOMAIN)' -i ${HOSTS_FILE}
yq e '.all.vars.nms_org = env(NMS_ORGANIZATION_NAME)' -i ${HOSTS_FILE}
yq e '.all.vars.nms_id = env(NMS_EMAIL_ID)' -i ${HOSTS_FILE}
yq e '.all.vars.nms_pass = env(NMS_PASSWORD)' -i ${HOSTS_FILE}

# Deploy Magma Orchestrator
ansible-playbook deploy-orc8r.yml
_

rm -rf /tmp/magma-deployer
