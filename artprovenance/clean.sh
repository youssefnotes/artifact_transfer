#!/bin/bash
function main {
	echo "############################################################"
	echo "#################Shutting down containers###################"
	echo "############################################################"
	docker-compose --project-name art -f docker-compose-provenance.yaml down
	echo "############################################################"
	echo "##Deleting directories:      ###############################"
	echo "==>artifacts/channels        ###############################"
	echo "==>artifacts/orderer         ###############################"
	echo "==>config/crypto-config      ###############################"
	echo "############################################################"
	rm -fdr artifacts/channels
	rm -fdr artifacts/orderer
	rm -fdr config/crypto-config
	rm -fdr logs
}
main