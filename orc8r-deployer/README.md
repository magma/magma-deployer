# Orc8r-deployer
The Orc8r Deployer has two primary approaches:

1. A quick deployer that uses the current magma master branch and standard orc8r artifacts.
2. A customized deployer that better allows for deployment-specific modifications. While any modifications are possible in this approach, the primary are likely to be things like use of different helm chart and container images.

## Quick Deployer

This document describes the Quick install process: https://magma.github.io/magma/docs/next/orc8r/deploy_using_ansible

```bash
sudo bash -c "$(curl -sL https://github.com/magma/magma-deployer/raw/main/deploy-orc8r.sh)"
```

## Customized Deployer

Many users will want to have the simplicity of the quick deployer but will need to make some tweaks to the deployment in order to fit their environment and needs.

To start the process, create a deployer working environment. Do this from a login other than the `magma` login (e.g., `ubuntu`). 

```bash
cd ~
git clone https://github.com/jblakley/magma-deployer # To change after upstreamed
cd magma-deployer
git checkout agw-orc8r # To change after upstreamed
cd orc8r-deployer
bash ./deploy-orc8r.sh $(pwd)
```

The above steps are equivalent to running the quick deployer but set up an environment where you can make modifications and redeploy.

If `deploy-orc8r.sh` fails the first time through when bringing up RKE or if you need to redeploy after making changes to magma-deployer or magma later, the following seems to recover the system.  You may need to run the following.

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

After deployment has successfully finished, switch to `magma` user 

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

## Making changes to magma/orc8r
If you expect to make changes to the magma code itself, now is good time to:

```
cd ~
git clone https://github.com/magma/magma
cd magma/orc8r
git checkout <your_prefered_branch>
```

## Making changes to Orc8r Helm Charts



## Making changes to Orc8r containers



## Other Tips & Tricks



### K9s for Management

*For a handy, simple kubernetes management tool, try [k9s](https://github.com/derailed/k9s)*

```bash
K9SVER=v0.32.5
ARCH=amd64
wget https://github.com/derailed/k9s/releases/download/${K9SVER}/k9s_Linux_${ARCH}.tar.gz
tar xvzf k9s_Linux_${ARCH}.tar.gz
sudo cp k9s /usr/local/bin
k9s
```

