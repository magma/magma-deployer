# Magma-Deployer
Is a Magma project to simplify deployment of the components of the Magma Platform. The deployable components include the *Orchestrator aka Orc8r*, the *Access Gateway aka AGW*, the *Federation Gateway aka FEG (future)*, and the *Domain Proxy aka DP (future)*. There are multiple deployment methods and target environments possible for these components. At this time, magma-deployer enables the following deployments:

| Component | Version | Host                                                 | Deployment Model                                             |
| --------- | ------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| Orc8r     | v1.9    | Ubuntu 22.04 Bare Metal or Virtual Machine           | Ansible playbook(s) and helm into K8s cluster                |
| AGW       | v1.9    | Ubuntu 20.04  Bare Metal or Virtual Machine (2 NICs) | Ansible playbook(s) and docker-compose into docker containers |

## Out of Scope (at this time)

* Although other deployment models exist (e.g., Terraform, AWS-specific, Vagrant VMs, non-containerized AGW, k8s AGW), they are not currently implemented in magma-deployer.
* Magma-deployer does not currently support FEG or DP deployments
* Magma-deployer ends when the AGW successfully connects to the Orc8r. Follow on tasks of adding eNodeBs and gNodeBs, subscribers, configuring for 5G and connecting UEs are considered post-deployment steps.

## Basic Workflow

A minimal new deployment begins with an Orc8r and a single AGW.  To have a full standalone network, an eNodeB (LTE) or gNodeB (5G) and a compatible UE and SIM are needed. The steps in the deployment are:

1. Deploy Orc8r using orc8r-deployer.
2. Deploy an AGW using agw-deployer. You will need information from step #1 during step #2 and beyond.
3. Connect the AGW to the Orc8r

----

*Magma-deployer ends here.*

-----

4. [optional] Configure the network for 5G
5. Connect eNodeB or gNodeB to AGW and provision in Orc8r
6. Provision a UE and SIM for the network
7. Provision a subscriber in Orc8r
8. Connect the UE to the network

Now, head to orc8r-deployer. <link>

