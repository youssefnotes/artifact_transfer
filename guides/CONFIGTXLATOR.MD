# Reconfiguring with configtxlator

## Needed Housekeeping
1. create a folder for new organization
2. create configtx.yaml
```
################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:
    - &DEArt
        # DefaultOrg defines the organization which is used in the sampleconfig
        # of the fabric.git development environment
        Name: DEArtMSP

        # ID to load the MSP definition as
        ID: DEArtMSP

        MSPDir: crypto-config/peerOrganizations/bauhaus.de/msp

        AnchorPeers:
            # AnchorPeers defines the location of peers which can be used
            # for cross org gossip communication.  Note, this value is only
            # encoded in the genesis block in the Application section context
            - Host: peer0.bauhaus.de
              Port: 7051
```
3. create crypto-config.yaml
```
# ---------------------------------------------------------------------------
# "PeerOrgs" - Definition of organizations managing peer nodes
# ---------------------------------------------------------------------------
PeerOrgs:
  - Name: DEArt
    Domain: bauhaus.de
    Template:
      Count: 2
    Users:
      Count: 1
```
4. use the the configtxgen utility to print out the Org3-specific configuration material in JSON representation.
`configtxgen -printOrg Org3MSP > ./channel-artifacts/org3.json`

> This file contains the modification policy definitions for Org3, as well as three important certificates presented in base 64 format: 
> admin user cert,CA root cert and TLS root cert.In an upcoming step we will append this JSON object to the channel configuration.

5. Copy the Orderer Org's MSP material into the Org3 ``crypto-config`` directory. In particular, we are concerned with
the Orderer's TLS root cert, which will allow for secure communication between Org3 entities and the network's ordering node.
`cp -r crypto-config/ordererOrganizations org3-artifacts/crypto-config/`

## Start the ``configtxlator`` server

The update process makes use of the configuration translator tool - ``configtxlator``.
This tool provides a true stateless REST API, independent of the SDK, to simplify configuration tasks in Hyperledger Fabric blockchain networks.
The tool converts easily between different equivalent data representations/formats.
For example, in one mode of tool operation, the tool performs conversions between the binary protobuf format to a human-readable JSON textual format, and vice-versa.
Additionally, the tool can compute configuration updates based on the differences between two different sets of configurations transactions.

1. exec into the CLI container.
> _Recall that this container has been bootstrapped with the MSP material for Org1, meaning that any steps where we want to act on behalf of Org2 will require the export of MSP-specific environment variables._
`docker exec -it cli bash`

2. Install the ``jq`` tool into the container.  This tool allows us script interactions with JSON objects returned by the ``configtxlator`` tool.
`apt update && apt install jq`

3. Start the ``configtxlator`` REST server
`configtxlator start &`

4. Set the URL
`CONFIGTXLATOR_URL=http://127.0.0.1:7059`

5. Export the ``ORDERER_CA`` and ``CHANNEL_NAME`` variables

- `export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem`

 `export CHANNEL_NAME=mychannel`

6. Check to make sure the variables have been properly set
`echo $ORDERER_CA && echo $CHANNEL_NAME`

Now we have a running REST server within the CLI container and we have exported our two key environment variables
``ORDERER_CA`` & ``CANNEL_NAME``.

## Form the channel update objects

1. Let's go fetch the most recent config block for the channel - ``mychannel``.
`peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA`

_The above command applies an arbitrary name - ``config_block.pb`` - to this binary protobuf channel configuration block.  You do have the ability to alter the naming conventions for the returned protobuf and JSON objects, however you should follow an approach that will allow for easy and intuitive identification._

> When you issued the ``peer channel fetch`` command, there was a decent amount of output in the terminal.
> The last line in the logs is of interest:
> ```2017-11-07 17:17:57.383 UTC [channelCmd] readBlock -> DEBU 011 Received block: 2```

> This is telling us that the most recent configuration block for ``mychannel`` is actually block 2,
> **NOT** the genesis block.  By default, the ``peer channel fetch config`` command
> returns the most **recent** configuration block for the targeted channel, which is block 2 in our case.
> When our scenario executed, the embedded script made two additional configuration updates to the channel.  Namely, anchor peers for
> our two organizations - ``egyptianmuseum.org`` & ``louvre.fr`` - were defined by means of two separate channel update transactions.  
> As such we have the following configuration sequence: 
> - block 0 - genesis;
> - block 1 - Org1 anchor peer update; 
> - block 2 - Org2 anchor peer update.

2. Now we will make use of the ``configtxlator`` server and decode this channel configuration block into human-readable and editable JSON format.
`curl -X POST --data-binary @config_block.pb "$CONFIGTXLATOR_URL/protolator/decode/common.Block" | jq . > config_block.json`

> We are naming the decoded output - ``config_block.json``.  Again, you are free to apply your own naming conventions throughout these steps.
> If you issue an ``ls`` within the CLI container, you should see our two objects:  the binary protobuf channel configuration 
> - ``config_block.pb`` - and the JSON representation of this object - ``config_block.json``.

3. Now we need to scope the ``config_block.json`` object and strip away all of the encapsulating wrappers.  We are not concerned with the headers, metadata, creator signature, etc., but rather only with the configuration definition inside the transaction.  We accomplish this by means of the ``jq`` tool:
`jq .data.data[0].payload.data.config config_block.json > config.json`

4. This leaves us with a stripped down JSON object - ``config.json`` - which will serve as the baseline for our config update.  
We'll use the ``jq`` tool once more to append the org3 configuration definition - ``org3.json`` - 
and name this new file - ``updated_config.json``.
`jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json >& updated_config.json`

_Now, within the CLI container we have two JSON files of interest - ``config.json`` & ``updated_config.json``.  The initial file contains only Org1 and Org2 material, whereas the aptly named "updated config" file contains all three orgs.  At this point it's simply a matter of re-encoding these two JSON files and calculating the delta._

1. First, encode ``config.json`` to ``config.pb``
`curl -X POST --data-binary @config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > config.pb`

2. encode ``updated_config.json`` to ``updated_config.pb``
`curl -X POST --data-binary @updated_config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > updated_config.pb`

3. use the ``configtxlator`` server to calculate the delta between these two config protos.  This command will output a new protobuf binary named - ``config_update.pb``
`curl -X POST -F channel=$CHANNEL_NAME -F "original=@config.pb" -F "updated=@updated_config.pb" "${CONFIGTXLATOR_URL}/configtxlator/compute/update-from-configs" > config_update.pb`

4. 