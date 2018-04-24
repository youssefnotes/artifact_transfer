#!/bin/bash

function main {

	
		# Todo: save output of compose as log
		docker-compose --project-name art -f docker-compose-provenance.yaml start
}

main | tee logs/setup.log