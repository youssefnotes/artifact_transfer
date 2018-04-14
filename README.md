# HyperledgerProjects

The repository contains sample POC for different Hyperledger Fabric Components

## Folder Strucutre

- use case : sample use case for an Art Forgery Network
- artprovenance : contains the HLF related network configuration files
- decentralization : contains answers to decentralization section
- guides: containes steps to execute run the network & use of configtxlator to extend the network


###Using Kafka.

**_Network topology_**
- 3 Orderers
- 3 Zookeepers
- 4 Kafka brokers


To setup for firt time use `./setup.sh` or excute the commands manually according to your envirnoment.

### The following is a test script for the artifact transfer chaincode
### TODO: automate the test script

1. get the bash of container cli0.egyptianmuseum.org 
`docker exec -it cli0.egyptianmuseum.org bash`

2. add a new artifact with ["oldest book","The Oldest Intact European Book","owned", "british library"]
`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["create","oldest book","The Oldest Intact European Book","owned", "british library"]}'`

3. change owner of the oldest book from the british library to the greman library ["oldest book","german library"]
`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["transferOwner","oldest book","german library"]}'`

4. change status of the oldest book from owned to stolen ["oldest book","stolen"]
`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["setStatus","oldest book","stolen"]}'`

5. read artifact details ["oldest book"]
`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["read","oldest book"]}'`

### storing the keys
`cp -a .hfc-key-store/ ~/.hfc-key-store`

###Client app

`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Crook","Symbol of pharaonic power. Symbol of the god Osiris","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Amulet","Predynastic, and onward","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Senet","A board game","owned", "Egyptian Museum"]}'`
`curl -s -X POST  http://localhost:4000/invoke -H "content-type: application/json" -d '{"args":["egyptianmuseum","Benben stone","the top stone of the Egyptian pyramid",,"owned", "Egyptian Museum"]}'`
