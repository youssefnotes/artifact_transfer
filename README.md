# HyperledgerProjects

The repository contains a POC for using different Hyperledger Fabric Components

## Folder Strucutre

- use case : sample use case for an Art Forgery/Artifact Transfer Network
- artprovenance : contains the HLF related network configuration files
- decentralization : contains answers to decentralization section
- guides: containes steps to execute run the network & use of configtxlator to extend the network

### The `master` & `client_app` branches has the complete working poc

> Covering Kafka/Nodejs client SDK/Chain code

**_Network topology_**
- 3 Orderers
- 3 Zookeepers
- 4 Kafka brokers

### The [guides][guides/] section covers:
1. Artifact Transfer test Script
2. How to generate client app ceertificates
3. How to use CONFIGTXLATOR to ass a new org

### A working chain code example is available [here][/artprovenance/artifact/chaincode/artifact_transfer]

To setup for firt time use `./setup.sh` or excute the commands manually according to your envirnoment.

### The [runTestScript.sh][/artprovenance/runTestScript] is semi-automated test script for the artifact transfer chaincode

### Storing the keys
`cp -a .hfc-key-store/ ~/.hfc-key-store`

### Client App Test script

> the follwoing will trigger create function

`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Crook","Symbol of pharaonic power. Symbol of the god Osiris","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Amulet","Predynastic, and onward","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Senet","A board game","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Benben stone","the top stone of the Egyptian pyramid", "owned", "Egyptian Museum"]}'`
