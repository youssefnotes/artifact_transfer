#!/bin/bash
function main {
	echo "############################################################"
	echo "##Deleting directories : orderer, channels, crypto-config###"
	echo "############################################################"
	rm -frd orderer
	rm -frd channels
	rm -frd crypto-config
}
main