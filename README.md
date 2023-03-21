# magma-deployer

Quick Install:
```bash
sudo bash -c "$(curl -s https://raw.githubusercontent.com/magma/magma-deployer/main/deploy-orc8r.sh)"
```

Switch to `magma` user after deployment has finsished:
```bash
sudo su - magma
```

Once all pods are ready, setup NMS login:
```bash
cd ~/magma-galaxy
ansible-playbook config-orc8r.yml
```

You can get your `rootCA.pem` file from the following location:
```bash
cat ~/magma-galaxy/secrets/rootCA.pem
```
