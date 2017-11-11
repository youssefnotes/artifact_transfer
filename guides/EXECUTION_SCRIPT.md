# The following are the execution script to run over the art forgery network

### EgytpianMuseum.org (1st Org)

1. 	`docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -o orderer.art.ifar.org:7050 -c mainchannel -f MainChannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'`
		
2. `docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'`

3. `docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'`

4. `docker exec cli1.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'`

5. `docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artmanager -v 0'`

6. `docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer.art.ifar.org:7050 -C mainchannel -n artmanager -v 0 -c '{^"Args^":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA"`

7. `export ORDERER_CA=/var/hyperledger/crypto/orderer/msp/tlscacerts/tlsca.art.ifar.org-cert.pem`

8. `docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer.art.ifar.org:7050 -C mainchannel -n artmanager -v 0 -c '{\"Args\":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA"` 
		
### Louvre.fr (2nd Org)

1. `docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'`

2. `docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'`

3. `docker exec cli1.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'`