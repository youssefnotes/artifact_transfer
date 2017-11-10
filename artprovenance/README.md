## Sample network V0.1
=========

**Branch TLS** demonestrates the following technical capabilities:

1. Create a Network 
- Assume, we have two organisations the Egyptian museum and the Louvre. 
- Each organisation runs two peers in the network.

2. Create certificates using **cryptogen**.

3. Create a basic network using Docker Compose.

4. Add a channel **mainchannel** for egyptianmuseum and louvre to your network.

5.  Write a chaincode for a simple asset transfer and deploy it. (6 points)

- Give your asset at least two properties and use JSON to serialise it in the blockchain
> excute `peer chaincode invoke -n artmanager -v 0 -c '{"Args":["addNewArtifact", "EGYMUSEUM", "ARTID1234", "Sphinx"]}' -C mainchannel -o orderer.art.ifar.org:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA`

- Write a query function to prove asset transfers
> excute `peer chaincode query -n artmanager -v 0 -c '{"Args":["queryArtifactDetails", "EGYMUSEUM", "ARTID1234"]}' -C mainchannel -o orderer.art.ifar.org:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA`

6. Use Fabric CA to replace the certificates.

7. Enable TLS.

*Comments are added to docker-compose for step explanation
*To test the network, build the artifacts from scratch excute chmod +x setup.sh 