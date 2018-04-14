# Start up the network
./setup.sh

# The following is a test script for the artifact transfer chaincode
# TODO: automate the test script

# To get the logs of the containers/some envirnoment variable need to be adjusted to keep the log stream flowing; if disconnected use the same command
docker-compose --project-name art -f docker-compose-provenance.yaml logs -f

#1. get the bash of container cli0.egyptianmuseum.org 
docker exec -it cli0.egyptianmuseum.org bash

#2. add a new artifact with ["oldest book","The Oldest Intact European Book","owned", "british library"]
docker exec cli0.egyptianmuseum.org -c "peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["create","oldest book","The Oldest Intact European Book","owned", "british library"]}'"

#3. change owner of the oldest book from the british library to the greman library ["oldest book","german library"]
docker exec cli0.egyptianmuseum.org -c "peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["transferOwner","oldest book","german library"]}'"

#4. change status of the oldest book from owned to stolen ["oldest book","stolen"]
docker exec cli0.egyptianmuseum.org -c "peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["setStatus","oldest book","stolen"]}'"

#5. read artifact details ["oldest book"]
docker exec cli0.egyptianmuseum.org -c "peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["read","oldest book"]}'"

#6. get the bash of container cli1.louvre.fr 
docker exec -it cli1.louvre.fr bash

#7. read artifact details ["oldest book"]; status should be stolen
docker exec cli1.louvre.fr -c "peer chaincode invoke -C mainchannel -n artifact_transfer -v 0 -o orderer0.art.ifar.org:7050 -c '{"Args":["read","oldest book"]}'"

# Shutdown and remove containers/dev images
./shutdown.sh