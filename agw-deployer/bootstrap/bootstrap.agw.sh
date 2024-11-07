#!/bin/bash
cat bootstrap_start.txt
test -f .env || bash -c "echo No '.env file; exiting'"; test -f .env || exit
source .env
echo "Checking .env completeness"
test -n "${ARCH}" || echo 'No ARCH defined; exiting'; test -n "${ARCH}" || exit
test -n "${USER}" || echo 'No USER defined; exiting'; test -n "${USER}" || exit
test -d "${RECIPE_HOME}" || echo 'No RECIPE_HOME; exiting'; test -d "${RECIPE_HOME}" || exit
test -d "${PLAYBOOK_HOME}" || echo 'No PLAYBOOK_HOME; exiting'; test -d "${PLAYBOOK_HOME}" || exit
test -n "${CLOUDLET_IP}" || echo 'No CLOUDLET_IP defined; exiting'; test -n "${CLOUDLET_IP}" || exit
test -n "${S1_IP}" || echo 'No S1_IP defined; exiting'; test -n "${S1_IP}" || exit
test -n "${NODEB_IP}" || echo 'No NODEB_IP defined; exiting'; test -n "${NODEB_IP}" || exit
test -n "${IPGATEWAY_IP}" || echo 'No IPGATEWAY_IP defined; exiting'; test -n "${IPGATEWAY_IP}" || exit
test -n "${CLOUDLET_DN}" || echo 'No CLOUDLET_DN defined; exiting'; test -n "${CLOUDLET_DN}" || exit
test -n "${MAGMA_DN}" || echo 'No MAGMA_DN defined; exiting'; test -n "${MAGMA_DN}" || exit
test -n "${PRIVATE_KEY}" || echo 'No PRIVATE_KEY defined; exiting'; test -n "${PRIVATE_KEY}" || exit
test -n "${ROOT_CA_PATH}" || echo 'No ROOT_CA_PATH defined; exiting'; test -n "${ROOT_CA_PATH}" || exit
test -n "${ORC8R_IP}" || echo 'No ORC8R_IP defined; exiting'; test -n "${ORC8R_IP}" || exit
# test -n "${BLANK}" || echo 'No BLANK defined; exiting'; test -n "${BLANK}" || exit

ls ../tmp || mkdir -v ../tmp

# UPDATE SYSTEM
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# INSTALL PYTHON
sudo apt install python3-pip -y # Install python early for other things that require it. 20.04 comes with python 3.8 by default
sudo pip3 install --upgrade pip
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# MAKE TMP DIRECTORY
ls ../tmp || mkdir ../tmp

# INSTALL ANSIBLE
sudo apt install ansible -y
pip install ansible tqdm jinja2 python-dotenv
chmod +x ../bin/env2jinja2.py


# START ANSIBLE RECIPE
echo ${PLAYBOOK_HOME}

# ANSIBLE: Set up ansible playbook
cd ${PLAYBOOK_HOME}
ansible-galaxy collection install -r ./collections/requirements.yml

echo "Updating hosts.yaml from .env; NOTE: Doesn't overwrite previous values only template placeholders"
export PYTHONPATH=../lib
../bin/env2jinja2.py
cp -pv ../tmp/hosts.yml ${PLAYBOOK_HOME}/

# ANSIBLE: 
ansible-playbook deploy-common-system.yml -K

cat $RECIPE_HOME/bootstrap/bootstrap_end.txt
