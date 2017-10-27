Art Forgery Sample network V0.1
===============================

The project files will cover the below technical requirements:-

===> Create a Network
		Assume, we have two organisations Org1 and Org2. Each organisation runs two peers in the network.
===> Create certificates using cryptogen.
===> Create a basic network using Docker Compose.
===> Add a channel testchannel for Org1 and Org2 to your network.
===> Write a chaincode for a simple asset transfer and deploy it. (6 points) --in progress--
	 - Give your asset at least two properties and use JSON to serialise it in the blockchain
	 - Write a query function to prove asset transfers
	 - Include comments in your source code.
===> Use Fabric CA to replace the certificates. (4 points) --done--
===> Enable TLS. (5 points)

*Comments are added to docker-compose for step explanation

*To test the network, simply execute the start.sh executable 