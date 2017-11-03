#!/bin/bash

function withTLS {
	# sleep 10
		#Setup with tls
		echo "########egyptianmuseum peer"
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -o orderer.art.ifar.org:7050 -c mainchannel -f MainChannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		docker exec cli1.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode install -p chaincode/artmanager -n artmanager -v 0'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer chaincode instantiate -o orderer.art.ifar.org:7050 -C mainchannel -n artmanager -v 0 -c '{"Args":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		echo "########louvre peer"
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
		docker exec cli1.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		echo "########bauhaus peer"
		docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f DEArtMSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA'
}

function withoutTLS {
	#Setup without tls
		echo "########egyptianmuseum peer"
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -o orderer.art.ifar.org:7050 -c mainchannel -f MainChannel.tx'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx'
		docker exec cli1.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli1.egyptianmuseum.org bash -c 'peer chaincode install -p chaincode/artmanager -n artmanager -v 0'
		docker exec cli1.egyptianmuseum.org bash -c 'peer chaincode instantiate -n artmanager -v 0 -c '{"Args":[""]}' -C mainchannel'

		echo "########louvre peer"
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx'
		docker exec cli1.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli1.louvre.fr bash -c 'peer chaincode install -p chaincode/artmanager -n artmanager -v 0'

		echo "########bauhaus peer"
		docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.bauhaus.de bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f DEArtMSPanchors.tx'
		docker exec cli0.bauhaus.de bash -c 'peer chaincode install -p chaincode/artmanager -n artmanager -v 0'



}		


function main {


		#cleaning old directories
		# ./clean.sh
		#Setting bin for out executables
		# export PATH=${PWD}/../bin:${PWD}:$PATH
		#setting CFG needed for configtxgen

		# echo "################################################"
		# echo "Generating reuired crypto material for fabric CA"
		# echo "################################################"
		# ./crypto.sh
		# cd config
		# sleep 1
		echo "########################################################"
		echo "========================DONE============================"
		echo "########################################################"
		echo "Creating folders:"
		echo "../artifacts ../artifacts/orderer/ ../artifacts/channels/"
		echo "########################################################"
		mkdir -p -v ./artifacts
		mkdir -p -v ./artifacts/orderer
		mkdir -p -v ./artifacts/channels
		mkdir -p -v ./logs
		echo "########################################################"
		echo "========================DONE============================"
		cd config
		echo "########################################################"
		echo "Generating reuired crypto material using cryptogen tool"
		echo "########################################################"
		cryptogen generate --config=crypto-config.yaml
		echo "Defaulting FABRIC_CFG_PATH to ${PWD}"
	    export FABRIC_CFG_PATH=./
		echo "#################################"
		echo "####Generating Genesis Block#####"
		echo "#################################"
		configtxgen -profile ArtProvenanceOrdererGenesis -outputBlock ../artifacts/orderer/genesis.block
		sleep 1
		echo "########################################################"
		echo "========================DONE============================"
		echo "########################################################"
		echo "###################Generating Channels##################"
		echo "########################################################"
		echo "generating channel 'mainchannel'"
		configtxgen -profile MainChannel -outputCreateChannelTx ../artifacts/channels/MainChannel.tx -channelID mainchannel
		echo "updating anchrpeer for EGArt"
		configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/EGArtMSPanchors.tx -channelID mainchannel -asOrg EGArtMSP
		echo "updating anchrpeer for FRArt"
		configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/FRArtMSPanchors.tx -channelID mainchannel -asOrg FRArtMSP
		echo "updating anchrpeer for DEArt"
		configtxgen -profile MainChannel -outputAnchorPeersUpdate ../artifacts/channels/DEArtMSPanchors.tx -channelID mainchannel -asOrg DEArtMSP
		cd ..
		# Todo: save output of compose as log
		docker-compose --project-name art -f docker-compose-provenance.yaml up
		# execute setup steps with TLS
		# withTLS
		# withoutTLS


		
}

main | tee logs/setup.log