# magma-deployer
Quick deployer of the Magma Orchestrator based mostly on ansible.

Docs: https://magma.github.io/magma/docs/next/orc8r/deploy_using_ansible

Quick Install:

```bash
sudo bash -c "$(curl -sL https://github.com/magma/magma-deployer/raw/main/deploy-orc8r.sh)"
```

CMU Controlled Install:

```bash
git clone https://github.com/jblakley/magma-deployer
cd magma-deployer
git checkout cmu
bash ./deploy-orc8r.sh $(pwd)
```

Sometimes, this fails the first time through when bringing up RKE. The following seems to recover it. From the `magma` account:

```bash
# Reboot and ...
cd ~/magma-deployer/RKE
rke remove
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
cd ..
ansible-playbook deploy-orc8r.kml
```

Switch to `magma` user after deployment has finsished:

```bash
sudo su - magma
```

Once all pods are ready, setup NMS login:

```bash
cd ~/magma-deployer
ansible-playbook config-orc8r.yml
```

You can get your `rootCA.pem` file from the following location:

```bash
cat ~/magma-deployer/secrets/rootCA.pem
```
