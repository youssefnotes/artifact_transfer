**Art Forgery Sample network V0.1**
===========================

Switch to the branch according to the required feature:-
Master branch is updated and commented for detailed config files explanation.

**Branch TLS**

> 1- Create a Network 
- Assume, we have two organisations the Egyptian museum and the Louvre. 
- Each organisation runs two peers in the network.
2- Create certificates using **cryptogen**.
3- Create a basic network using Docker Compose.
4- Add a channel **mainchannel** for Org1 and Org2 to your network.
5-  Write a chaincode for a simple asset transfer and deploy it. (6 points) --in progress--
- Give your asset at least two properties and use JSON to serialise it in the blockchain
- Write a query function to prove asset transfers
- Include comments in your source code.
6- Use Fabric CA to replace the certificates. (4 points) --done--
7- Enable TLS. (5 points)

*Comments are added to docker-compose for step explanation
*To test the network, build the artifacts from scratch excute chmod +x setup.sh 