#!/bin/bash

function withTLS {
	# sleep 10
		export ORDERER_CA=/var/hyperledger/crypto/orderer/msp/tlscacerts/tlsca.art.ifar.org-cert.pem
		#Setup with tls
		echo "########egyptianmuseum peer"
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -o orderer0.art.ifar.org:7050 -c mainchannel -f MainChannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --timeout 30'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'peer channel list'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer0.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		docker exec cli1.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli1.egyptianmuseum.org bash -c 'peer channel list'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artmanager -v 0'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artifact_transfer -v 0'
		docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer0.art.ifar.org:7050 -C mainchannel -n artmanager -v 0 -c '{\"Args\":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA"
		docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer0.art.ifar.org:7050 -C mainchannel -n artifact_transfer -v 0 -c '{\"Args\":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA"

		echo "########louvre peer"
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer0.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		docker exec cli1.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		# echo "########bauhaus peer"
		# docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel join -b mainchannel.block'
		# docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f DEArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
}



function withOutTLS {
	# sleep 10
		#Setup without tls
		echo "########egyptianmuseum peer"
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -o orderer0.art.ifar.org:7050 -c mainchannel -f MainChannel.tx'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'peer channel list'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer0.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx'
		docker exec cli1.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli1.egyptianmuseum.org bash -c 'peer channel list'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artmanager -v 0'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artifact_transfer -n artifact_transfer -v 0'
		docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer0.art.ifar.org:7050 -C mainchannel -n artmanager -v 0 -c '{\"Args\":[\"\"]}'"
		docker exec cli0.egyptianmuseum.org bash -c "cd channels && peer chaincode instantiate -o orderer0.art.ifar.org:7050 -C mainchannel -n artifact_transfer -v 0 -c '{\"Args\":[\"\"]}'"
		
		echo "########louvre peer"
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer0.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx'
		docker exec cli1.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli1.louvre.fr bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artmanager -v 0'

		# echo "########bauhaus peer"
		# docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel join -b mainchannel.block'
		# docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f DEArtMSPanchors.tx'
}

# The following is a test script for the artifact transfer chain code
# TODO: automate the test script

#1. get the bash of container cli0.egyptianmuseum.org 
#`docker exec -it cli0.egyptianmuseum.org bash`

#2. add a new artifact with ["oldest book","The Oldest Intact European Book","owned", "british library"]
#`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["create","oldest book","The Oldest Intact European Book","owned", "british library"]}'`

#3. change owner of the oldest book from the british library to the greman library ["oldest book","german library"]
#`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["transferOwner","oldest book","german library"]}'`

#4. change status of the oldest book from owned to stolen ["oldest book","stolen"]
#`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["setStatus","oldest book","stolen"]}'`

#5. read artifact details ["oldest book"]
#`peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["read","oldest book"]}'`


function main {


		#cleaning old directories
		# ./clean.sh
		#Setting bin for out executables
		# export PATH=${PWD}/../bin:${PWD}:$PATH
		#setting CFG needed for configtxgen

		echo "################################################"
		echo "Generating reuired crypto material for fabric CA"
		echo "################################################"
		./crypto.sh
		# cd config
		sleep 1
		echo "========================DONE============================"
		echo "########################################################"
		echo "Creating folders:"
		echo "../artifacts ../artifacts/orderer/ ../artifacts/channels/"
		echo "########################################################"
		# mkdir -p -v ./artifacts
		mkdir -p -v ./artifacts/orderer
		mkdir -p -v ./artifacts/channels
		mkdir -p -v ./logs
		echo "========================DONE============================"
		cd config
		# echo "########################################################"
		# echo "Generating reuired crypto material using cryptogen tool"
		# echo "########################################################"
		# cryptogen generate --config=crypto-config.yaml
		echo "Defaulting FABRIC_CFG_PATH to ${PWD}"
	    export FABRIC_CFG_PATH=./
		echo "####Generating Genesis Block#####"
		echo "#################################"
		../bin/configtxgen -profile ArtProvenanceOrdererGenesis -outputBlock ../artifacts/orderer/genesis.block
		sleep 1
		echo "========================DONE============================"
		echo "###################Generating Channels##################"
		echo "########################################################"
		echo "generating channel 'mainchannel'"
		../bin/configtxgen -profile MainChannel -outputCreateChannelTx ../artifacts/channels/MainChannel.tx -channelID mainchannel
		echo "updating anchorpeer for EGArt"
		../bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/EGArtMSPanchors.tx -channelID mainchannel -asOrg EGArtMSP
		echo "updating anchorpeer for FRArt"
		../bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/FRArtMSPanchors.tx -channelID mainchannel -asOrg FRArtMSP
		# echo "updating anchrpeer for DEArt"
		# configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/DEArtMSPanchors.tx -channelID mainchannel -asOrg DEArtMSP
		cd ..
		# Todo: save output of compose as log
		docker-compose --project-name art -f docker-compose-provenance.yaml up
		# execute setup steps with TLS
		# CONTAINER_IDS=$(docker ps -aq)
		# withTLS
		# docker attach $CONTAINER_IDS


		
}

main