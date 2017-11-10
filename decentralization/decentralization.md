# The following are notes on the decentralization topic

## If you want to run the network on multiple hosts, you have a few options.

### You could run the nodes native on hosts. Why is this impractical? (3 points)
> - It should be noted that Hyperledger Fabric does not deliver a complete set of binaries for all operating systems. There are native binaries for the various tools (configtxgen, cryptogen, configtxlator and peer) available for Windows, MacOSX, and Linux (for X86, ppc and s390 architectures). There are published Docker images for Ubuntu. Building Centos/RHEL images or binaries should be a straight-forward process, but is not presently a tested/supported configuration. The Node and Java SDKs should run just about anywhere.
> - It should also be noted that you cannot run without Docker, as chaincode is run in independent containers, managed by the peer. Hence, trying to avoid use of Docker is really a forgone conclusion - you cannot.
> - To build and run the nodes natively we are exposed to taking care of the software logisitcs and dependecy
> - By using the images we benefit from a complete series of tests for functionality, stability, and performance across the supported system platforms
> - Container make it practical to run nodes in cloud

### You could use various services, e.g. Docker Swarm or Kubernetes.Explain briefly Swarm and Kubernetes.  (8 points)
> Decoupling application from infrastucture creates new oppertunities
> Swarm:
> - Docker Swarm1 is a utility that is used to create a cluster of Docker hosts that can be interacted with as if it were a single host.

>Kubernetes: a platform for automating deployment, scaling and operations Problem
> - Applications and OS share filesystem & use OS distribution package manager
> - Entangled with each other and with host (Excutable,Configurtions,Shared libraries,Process and lifecycle)
>Solution
> - OS-level virtualization
> - Isolated from each other and from host(filesystem, processes, resources)
> - Light weight and fast => 1:1 app to image (unlocks benifits of microservices, decouple build from deployment,consistency from development to > production, portable accross OS)

>Kubernates
	- is a container centeric infrastructure which include more than just containers
	- facilitates managment of containers in production
	- provides a foundation for building a workload-managment ecosystem

### Name some sources for the next steps to use them for Hyperledger Fabric.
> - [A first attempt at HyperLedger Fabric + Kubernetes](https://medium.com/wearetheledger/a-first-attempt-at-hyperledger-fabric-kubernetes-66e43b12a211)
> - [Getting started with Hyperledger on Kubernetes](https://developers.redhat.com/blog/2016/11/01/getting-started-with-hyperledger-on-kubernetes/)
> - [HL on Swarm](https://github.com/ChoiSD/hyperledger_on_swarm)
> - [HLF under Swarm](https://github.com/stylixboom/param_daemon/blob/master/hyperledger_under_swarm.pdf)
> - [Param Daemon Swarm](https://github.com/stylixboom/param_daemon)
> - [Jira:Provide a sample deployment and topology for Docker Swarm Mode](https://jira.hyperledger.org/browse/FAB-3338)
> - [Swarm official](https://docs.docker.com/engine/swarm/)

### You can use IBM Bluemix. Tell us what it offers in regard to Hyperledger Fabric. (2 points)
> - Initiate a new blockchain network including setting democratic network policies and inviting new members to join.
> - Join a network, as a new member, based on an invite from the network initiator.
> - A Certificate Authority (CA) – for issuing certificates to other network participants to enroll in the network
> - A Network Peer – enabling the invocation and validation of transactions
> - Network Dashboard – for managing and monitoring network resources
> - [Deploying Hyperledger Fabric on an IBM Bluemix Kubernetes Cluster with Cloudsoft AMP](https://www.cloudsoft.io/blog/deploying-hyperledger-fabric-on-ibm-bluemix-kubernetes-cluster-using-amp)

### There is a project called Hyperledger Cello. Explain, what it aims to do and where one can learn more about it, as well how to get support. (2 points)
> Hyperledger Cello is a blockchain provision and operation system, which helps manage blockchain networks.
> Hyperledger Cello aims to bring the on-demand “as-a-service” deployment model to the blockchain ecosystem to reduce the effort required for
> creating, managing and terminating blockchains. It provides a multi-tenant chain service efficiently and automatically on top of various
> infrastructures, e.g.,baremetal, virtual machine, and more container platforms.
> Using Cello, everyone can easily:
> - Build up a Blockchain as a Service (BaaS) platform quickly from the scratch.
> - Provision customizable Blockchains instantly, e.g., a Hyperledger fabric network v1.0.
> - Maintain a pool of running blockchain networks on top of baremetals, Virtual Clouds (e.g., virtual machines, vsphere Clouds), Container
> clusters (e.g., Docker, Swarm, Kubernetes).
> - Check the system status, adjust the chain numbers, scale resources... through dashboards.

> [Cello Github](https://github.com/hyperledger/cello)
> [Cello Wiki](https://wiki.hyperledger.org/projects/cello)
> for support use the [rocket chat](https://chat.hyperledger.org/channel/cello)
Try to put all this on less than one page, decentralisation.md or decentralisation.txt.