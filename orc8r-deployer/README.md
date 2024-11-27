# orc8r-deployer
Quick deployer of the Magma Orchestrator based mostly on ansible.

Docs: https://magma.github.io/magma/docs/next/orc8r/deploy_using_ansible

Quick Install:

```bash
sudo bash -c "$(curl -sL https://github.com/magma/magma-deployer/raw/main/deploy-orc8r.sh)"
```

CMU Controlled Install:

```bash
git clone https://github.com/jblakley/magma-deployer
git checkout agw-orc8r
cd magma-deployer/orc8r-deployer
bash ./deploy-orc8r.sh $(pwd)
```

Sometimes, this fails the first time through when bringing up RKE. The following seems to recover it. From the `magma` account:

```bash
# Reboot and ...
cd ~/magma-deployer/orc8r-deployer/rke
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

*For a handy, simple kubernetes management tool, try [k9s](https://github.com/derailed/k9s)*

```bash
K9SVER=v0.32.5
ARCH=amd64
wget https://github.com/derailed/k9s/releases/download/${K9SVER}/k9s_Linux_${ARCH}.tar.gz
tar xvzf k9s_Linux_${ARCH}.tar.gz
sudo cp k9s /usr/local/bin
k9s
```

To build your own helm repository for the orchestrator charts, create a private GitHub repo to use as your Helm chart repo. We'll refer to this as GITHUB_REPO.

Define some necessary variables

```
export GITHUB_REPO=GITHUB_REPO_NAME
export GITHUB_REPO_URL=GITHUB_REPO_URL
export GITHUB_USERNAME=GITHUB_USERNAME
export GITHUB_ACCESS_TOKEN=GITHUB_ACCESS_TOKEN
```

Next we'll run the package script. This script will package and publish the necessary Helm charts to the GITHUB_REPO. The script expects a deployment type to be provided, which will determine which orc8r modules are deployed.

Run the package script

${MAGMA_ROOT}/orc8r/tools/helm/package.sh -d fwa # or chosen deployment type

...

Uploaded orc8r charts successfully.
You can add -v option to overwrite the versions of the chart.

${MAGMA_ROOT}/orc8r/tools/helm/package.sh -d all

