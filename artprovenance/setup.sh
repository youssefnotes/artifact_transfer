#!/bin/bash

function main {


		#cleaning old directories
		# ./clean.sh
		#Setting bin for out executables
		# export PATH=${PWD}/../bin:${PWD}:$PATH
		#setting CFG needed for configtx

		cd config
		echo "Defaulting FABRIC_CFG_PATH to ${PWD}"
	    export FABRIC_CFG_PATH=${PWD}

		# echo "################################################"
		# echo "Generating reuired crypto material for fabric CA"
		# echo "################################################"
		# ./crypto.sh

		echo "########################################################"
		echo "Generating reuired crypto material using cryptogen tool"
		echo "########################################################"
		cryptogen generate --config=crypto-config.yaml
		sleep 1
		echo "########################################################"
		echo "========================DONE============================"
		echo "########################################################"
		echo "Creating folders:"
		echo "../artifacts ../artifacts/orderer/ ../artifacts/channels/"
		echo "########################################################"
		mkdir -p -v ../artifacts
		mkdir -p -v ../artifacts/orderer
		mkdir -p -v ../artifacts/channels
		mkdir -p -v ../logs
		echo "########################################################"
		echo "========================DONE============================"
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
		# echo "updating anchrpeer for DEArt"
		# configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/DEArtMSPanchors.tx -channelID mainchannel -asOrg DEArtMSP
		cd ..
		# Todo: save output of compose as log
		docker-compose --project-name art -f docker-compose-provenance.yaml up -d
		sleep 10
		
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel create -c mainchannel -f MainChannel.tx -o orderer.art.ifar.org:7050'
		
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.egyptianmuseum.org bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f EGArtMSPanchors.tx'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel join -b mainchannel.block'
		docker exec cli0.louvre.fr bash -c 'cd channels && peer channel update -o orderer.art.ifar.org:7050 -c mainchannel -f FRArtMSPanchors.tx'

}

main | tee logs/setup.log