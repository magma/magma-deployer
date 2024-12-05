# Orc8r-deployer
The Orc8r Deployer has two primary approaches:

1. A quick deployer that uses the current magma master branch and standard orc8r artifacts. Use this if you want a standard off-the-shelf Orc8r.
2. A customized deployer that better allows for deployment-specific modifications. While any modifications are possible in this approach, the primary are likely to be things like use of different helm chart and container images.

## Quick Deployer

This document describes the Quick install process: https://magma.github.io/magma/docs/next/orc8r/deploy_using_ansible

```bash
sudo bash -c "$(curl -sL https://github.com/magma/magma-deployer/raw/main/deploy-orc8r.sh)"
```

## Customized Deployer

Many users will like the simplicity of the quick deployer but will need to make some tweaks to the deployment in order to fit their environment and needs. The customized deployer approach let's you do that.

To start the process, create a deployer working environment. Do this from a login other than the `magma` login (e.g., `ubuntu`). 

```bash
# As ubuntu user
cd ~
git clone https://github.com/jblakley/magma-deployer # To change after upstreamed
cd magma-deployer
git checkout agw-orc8r # To change after upstreamed
cd orc8r-deployer
sudo bash ./deploy-orc8r-bootstrap.sh $(cd ..;pwd)
sudo su - magma
# As magma user
cd ~/magma-deployer/orc8r-deployer
ansible-playbook deploy-orc8r.yml
```

The above steps are equivalent to running the quick deployer but set up an environment where you can make modifications and redeploy. Assuming the deployment indicated no errors, you can monitor the startup of the orc8r with:

```
sudo su - magma
k9s
```

You should see all of the orc8r pods  eventually reach the `Running` state. Then run the configure step:

```
cd ~/magma-deployer/orc8r-deployer
ansible-playbook config-orc8r.yml
```

You should now be able to access NMS and the magma API. To access NMS and using the values entered when running `deploy-orc8r-bootstrap.sh`, enter `https://<NMS Organization>.nms.<Domain Name>` (e.g., `https://magma-test.nms.magma.local`) into a browser. You should get a browser login that accepts your `NMS email ID` and `NMS pasword` (default: `admin/admin`).  To access the API, import `~magma/magma-deployer/secrets/admin-operator.pfx` into your browser and enter `https://api.<Domain Name>/swagger/v1/ui` into a browser.

At this point, the Orc8r is deployed. Additional activities are either modifications to the deployment or magma and network administration tasks.

### Recovering from deployment failures
If the kubernetes deployment fails or you want to go back to the pre-kubernetes state of the platform, try the following. This procedure can also be use when you change helm charts or orc8r versions.

```bash
# Reboot and ...
# See orc8r-deployer/bin/recover.sh
sudo su - magma
cd ~/magma-deployer/orc8r-deployer/rke
rke remove
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
<implement any changes you want to magma and/or magma-deployer>
cd ..
ansible-playbook deploy-orc8r.kml
```

### Making changes to magma/orc8r
If you expect to make changes to the magma code itself, now is good time to:

```
cd ~
git clone https://github.com/magma/magma
cd magma/orc8r
git checkout <your_prefered_branch>
```

#### Making changes to Orc8r Helm Charts

There are a few reasons why you may want to update the helm charts for your orc8r deployment. The most common are likely changing the default container repository or the image tag. The basic steps are:

1. Create your own helm chart repository. Suggest using github for this. <REF>
2. Make your chart changes.
3. Package and push your changes to your helm chart repository. <REF>
4. Change the repo url in `~/magma-deployer/orc8r-deployer/roles/prerequisites/defaults/main.yml`
5. Rerun `ansible-playbook deploy-orc8r.yml`

### Making changes to Orc8r containers
How to build the Orc8r containers is out-of-scope of this project but see this reference <REF>. If you make changes to the orc8r containers (magmalte, controller, and nginx), you will need to:
1. Build and push them to a repository.
2. Update the helm charts to use that repository, image, and tag. See `~/magma/orc8r/cloud/helm/orc8r/values.yaml`
3. Package and push the helm charts as above.
4. Redeploy the orchestrator using `ansible-playbook deploy-orc8r.yml`


## Other Tips & Tricks



### K9s for Management

*For a handy, simple kubernetes management tool, try [k9s](https://github.com/derailed/k9s)*

orc8r-deployer installs k9s for amd64 by default but if you want to do it manually, see below.

```bash
K9SVER=v0.32.5
ARCH=amd64 # or arm64 or armv7
wget https://github.com/derailed/k9s/releases/download/${K9SVER}/k9s_Linux_${ARCH}.tar.gz
tar xvzf k9s_Linux_${ARCH}.tar.gz
sudo cp k9s /usr/local/bin
k9s
```

