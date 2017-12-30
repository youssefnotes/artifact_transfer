# HyperledgerProjects

The repository contains sample POC for different Hyperledger Fabric Components

## Folder Strucutre

- use case : sample use case for an Art Forgery Network
- artprovenance : contains the HLF related network configuration files
- decentralization : contains answers to decentralization section
- guides: containes steps to execute run the network & use of configtxlator to extend the network

## Each branch contains demonestration of various technical feature of the network

**Master**

- Create a Network > Assume, we have two organisations Org1 and Org2. Each organisation runs two peers in the network.
- Create certificates using cryptogen.
- Create a basic network using Docker Compose.
- Add a channel mainchannel for Org1 and Org2 to your network.
- Write a chaincode for a simple asset transfer and deploy it.
- Give your asset at least two properties and use JSON to serialise it in the blockchain
- Write a query function to prove asset transfers

>*Comments are added to docker-compose for envirnoment variable explanation*

To generate crypto materials and related artifacts (channels,genesis.block,anchor peers) for first time refer to 
`execute ./artprovenenace/setup.sh` 
*consider manually executing the commands,script still work in progress*

**simple_network**

**client_application**
- Write a client for Org3 using NodeJS SDK to invoke your chaincode.

**kafka**
Use Kafka OS.

**tls_net_extension**
- Use configtxlator to update the channel configuration.
- Refer to folder newOrg for the new organization configuration
- Refer to folder guides/CONFIGTXLATOR.MD

**tls**
- Enable TLS