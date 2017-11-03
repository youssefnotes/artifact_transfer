#!/bin/bash
function main {
	echo "############################################################"
	echo "#################Shutting down containers###################"
	echo "############################################################"
	docker-compose --project-name art -f docker-compose-provenance.yaml down

}
main