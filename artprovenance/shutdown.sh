#!/bin/bash
function main {
	echo "############################################################"
	echo "#################Shutting down containers###################"
	echo "############################################################"
	docker-compose --project-name art -f docker-compose-provenance.yaml down
	# remove containers
	docker rm $(docker ps --filter "name=cli0.louvre.fr" --filter "name=cli1.louvre.fr" --filter "name=cli0.egyptianmuseum.org" --filter "name=cli1.egyptianmuseum.org" -aq)
	docker rm $(docker ps --filter "name=peer0.louvre.fr" --filter "name=peer1.louvre.fr" --filter "name=peer0.egyptianmuseum.org" --filter "name=peer1.egyptianmuseum.org" -aq)
	docker rm $(docker ps --filter "name=orderer0.art.ifar.org" --filter "name=orderer1.art.ifar.org" --filter "name=orderer2.art.ifar.org" --filter "name=cli1.egyptianmuseum.org" -aq)
	docker rm $(docker ps --filter "name=kafka0" --filter "name=kafka1" --filter "name=kafka2" --filter "name=kafka3" -aq)
	docker rm $(docker ps --filter "name=ca.egyptianmuseum" --filter "name=ca.louvre" -aq)
	docker rm $(docker ps --filter "name=provenanceDB" -aq)
	docker rm $(docker ps --filter "name=zookeeper0" --filter "name=zookeeper1" --filter "name=zookeeper2" -aq)
	# remove chaincode docker images
	docker rmi $(docker images dev-* -q)
	echo "############################################################"
	echo "##Deleting directories : artifacts, config/crypto-config###"
	echo "############################################################"
	rm -fdr /artifacts/channels
	rm -fdr /artifacts/orderer
	rm -fdr config/crypto-config
	rm -fdr logs
}
main