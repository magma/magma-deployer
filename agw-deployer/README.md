# An AGW Deployment Recipe

This recipe deploys a standalone Magma AGW. It assumes that the orc8r-deployer or equivalent has already been run and the orc8r is accessible from the AGW machine.

DISCLAIMER: As with many deployment recipes, successful execution of the recipe is dependent on adjusting it to the specifics of a given environment. There is no guarantee this recipe can work "out of the box" in an arbitrary environment. Familiarity with Linux, Docker, Magma, IP Networking, and Ansible are likely to be needed to assure successful completion.

The recipe consists of the following primary steps:

1. Bootstrapping the initial environment
2. Deploy the Access Gateway
3. Connect the AGW to the Orc8r


### Prerequisites
Ubuntu 20.04 system with >100GB disk.

## Preparing your environment

You will need a physical system running Ubuntu 20.04 to deploy the **Magma Access Gateway (AGW)**.  The AGW requires two physical ethernet network interface cards. It is possible to run this same recipe in a virtual machine and this method has been tested in KVM/QEMU virtual machines. This recipe does not cover preparing a virtual machine.) This recipe assumes a bare metal install of the AGW. The AGW deployment uses docker and docker-compose deployment on the baremetal AGW system.

This recipe deploys a 5G network using Magma v1.9.

On the AGW System, set the environment variable `RECIPE_HOME` to the full pathname of the recipe folder (e.g,. `export RECIPE_HOME=/home/ubuntu/<repository>/magma-deployer/agw-deployer`).

## Deploy the AGW
Deployment of the AGW involves:

1. Configuring deployment specific environment variables and installing prerequisites (`.env`, `bootstrap.sh`, reboot)
2. Setting up the AGW network configuration  (`agwc-networking` playbook)
3. AGW docker-compose deployment (`agwc1` playbook, reboot, `agcw2` playbook)

The recipe is based on [this](https://magma.github.io/magma/docs/next/lte/deploy_install_docker) deployment guide.

### Initial configuration and installation of prerequistes

```
$ export RECIPE_HOME=<THIS DIRECTORY>
$ cd $RECIPE_HOME/bootstrap
$ cp template.env .env
$ vim .env
```

Edit the variables in .env to your preferred values. Then run:

```
$ bash bootstrap.sh
```
#### Notes on the `.env` variables:
- MAGMA_DN is the domain for your Orc8r
- PRIVATE_KEY is used for ansible hosts
- ROOT_CA_PATH  is the directory that contains your Orc8r's `rootCA.pem`
- At this writing:
  - `DOCKER_IMAGE_VERSION=20.10.21-0ubuntu1~20.04.2`
  - `DOCKER_COMPOSE_VERSION="v2.17.2"`

Reboot and test that docker works correctly (e.g., `docker ps` should respond with no containers running). You may want to to inspect the `$RECIPE_HOME/ansible/hosts.yml` file to validate the configuration set up by `bootstrap.sh`.

`bootstrap.sh` runs an ansible playbook called `deploy-common-system.yml`. If you run into issues during this phase, you may need rerun this playbook.
```
$ cd $RECIPE_HOME/ansible
$ ansible-playbook deploy-common-system.yml -K
```

### AGW network configuration

This will set up the AGW eth0 and eth1 interfaces

```
$ cd $RECIPE_HOME/ansible
$ ansible-playbook deploy-agwc-networking.yml -K
$ ip a
```
Verify that network for eth0 and eth1 are correct. You should be able to ping the Orc8r over eth0 and, if you have one, your gNB over eth1.

#### Notes on network configuration
- Your network renderer should be set to `NetworkManager` (check: `/etc/netplan/00-installer-config.yaml`)
- You may have issues with connectivity if this stage fails. Try to have direct console access during this playbook's execution
- Configuration of the AGW's ethernet networking has been one of the more problematic parts of bringing up an AGW. The playbook sets up the networking prior to actually deploying the gateway to prevent some issues that arise during. However, the deployment may impact some of the configuration.
- If you find that your network names are changing after reboots, make sure you do [this](https://askubuntu.com/questions/1255823/network-interface-names-change-every-reboot) Your grub configuration is wrong. Make it like this:

```
$ sudo vim /etc/default/grub
...
# GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
GRUB_CMDLINE_LINUX=""
...
$ sudo update-grub

$ reboot
```

### AGW docker-compose deployment (Part 1 and Part 2)

The docker-compose version of the AGW will be deployed in two stages.

Stage one sets up many of the agwc parameters and files and runs `agw_install_docker.sh`. This script clones magma and configures it for use. It installs the OpenVSwitch used by magma which requires a reboot.

```
$ cd $RECIPE_HOME/ansible
$ ansible-playbook deploy-agwc1.yml -K
```
Reboot.

Stage two completes the configuration and brings up the AGW containers. After this is complete, 

```
$ cd $RECIPE_HOME/ansible
$ ansible-playbook deploy-agwc2.yml -K
$ docker ps
```

All AGW containers should be running and showing healthy. The playbook will print the information needed to provision the AGW in the Orc8r. You can do that provisioning at this point. If you lose the info:

```
$ docker exec magmad show_gateway_info.py
```
Use this to provision the AGW in the Orc8r. 
On the Orc8r NMS, navigate to `Equipment->Gateways" from the left navigation bar, hit "Add New" on the upper right, and fill out the multi-step modal form. Use the secrets from above for the "Hardware UUID" and "Challenge Key" fields.

For now, you won't have any eNodeB's to select in the eNodeB dropdown under the "Ran" tab. This is OK, we'll get back to this in a later step.

At this point, you can validate the connection between your AGW and Orchestrator:

After the provisioning, restart the AGW services.

```
$ cd /var/opt/magma/docker
$ sudo docker compose --compatibility up -d --force-recreate
```
At this point, you can validate the connection between your AGW and Orchestrator.

The magma documentation says to run: sudo docker exec magmad checkin_cli.py to verify connectivity, however, as of this writing, there is a bug in the containerized version that will give this error even when you are connected to the Orc8r:
```
1. -- Testing TCP connection to controller.orc8r.magma18.livingedgelab.org:443 -- 
2. -- Testing Certificate -- 
3. -- Testing SSL -- 
4. -- Creating direct cloud checkin -- 

> Error: <_MultiThreadedRendezvous of RPC that terminated with:
        status = StatusCode.UNAVAILABLE
        details = "failed to connect to all addresses; last error: UNAVAILABLE: Socket closed"
        debug_error_string = "UNKNOWN:Failed to pick subchannel {created_time:"2022-10-21T19:23:22.773234625+02:00", children:[UNKNOWN:failed to connect to all addresses; last error: UNAVAILABLE: Socket closed {created_time:"2022-10-21T19:23:22.773231265+02:00", grpc_status:14}]}"
```
Two currently more reliable ways to validate Orc8r connection are:
```
$ sudo docker exec magmad cat /var/log/syslog|grep heart
```

Which should show multiple lines of:
```
Oct 21 13:33:43 agw-p18-2 eba229d6ac98[780]: INFO:root:[SyncRPC] Got heartBeat from cloud
```

And, from the NMS console in Orc8r, see if the AGW has checked in recently. Sometimes, this method will indicate a bad state even when all is OK, though. C.f.:

![image](https://github.com/user-attachments/assets/dd11f37e-c9f7-4fd2-8334-d0a3138b6545)

At this point, you should have a working dockerized AGW connected to the Orc8r. You can check the overall operation of the AGW.
```
$ docker ps
```
Should show something like this:
```
CONTAINER ID   IMAGE                                              COMMAND                   CREATED       STATUS                    PORTS     NAMES
e79702b02385   jblake1/agw_gateway_c:v1.9-asn-file-replace        "sh -c 'mkdir -p /va??"    3 hours ago   Up 3 hours (healthy)                sessiond
b6704d997323   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                policydb
f52dbfdd8ded   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                directoryd
4d2e50b32d30   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                state
56c728b646e5   jblake1/agw_gateway_c:v1.9-asn-file-replace        "sh -c '/usr/local/b??"    3 hours ago   Up 3 hours (healthy)                oai_mme
139d6db6b413   jblake1/agw_gateway_python:v1.9-asn-file-replace   "bash -c '/usr/bin/o??"    3 hours ago   Up 3 hours (healthy)                pipelined
3b4525dbcb75   jblake1/agw_gateway_c:v1.9-asn-file-replace        "/usr/local/bin/sctpd"    3 hours ago   Up 3 hours                          sctpd
fdd3bed312fc   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                enodebd
799a252f0930   jblake1/agw_gateway_c:v1.9-asn-file-replace        "/usr/local/bin/conn??"    3 hours ago   Up 27 minutes (healthy)             connectiond
40301d44eeb2   jblake1/agw_gateway_python:v1.9-asn-file-replace   "sh -c 'sleep 5 && /??"    3 hours ago   Up 3 hours (healthy)                mobilityd
f1f4e364f556   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/bin/bash -c '/usr/??"    3 hours ago   Up 3 hours (healthy)                redis
b2aec9583fd2   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                redirectd
01b33304ef65   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/bin/bash -c '/usr/??"    3 hours ago   Up 3 hours (healthy)                td-agent-bit
04acdbbf16a1   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                health
16acbcd25f63   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                monitord
2d7d3fef9d9c   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                subscriberdb
b713213bdee5   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                ctraced
dac051b19998   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/bin/bash -c '\n  /u??"   3 hours ago   Up 3 hours                          magmad
2e5a7c955ed6   jblake1/agw_gateway_python:v1.9-asn-file-replace   "sh -c '/usr/local/b??"    3 hours ago   Up 3 hours (healthy)                control_proxy
0c00fb1cb8d1   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                eventd
1ef9ee1cb5fc   jblake1/agw_gateway_python:v1.9-asn-file-replace   "/usr/bin/env python??"    3 hours ago   Up 3 hours (healthy)                smsd
```

## Other tools, tips, debugging suggestions

# Notes to be dealt with later

# TODO

