# Reconfiguring with configtxlator

## Get the needed binaries

`export VERSION=1.1.0-preview`

`export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')`

`curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/${ARCH}-${VERSION}/hyperledger-fabric-${ARCH}-${VERSION}.tar.gz | tar xz`

`mv configtxlator to /usr/local/bin`

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
4. first generate the crypto material for Org3

`./crypto.sh`

5. use the the configtxgen utility to print out the Org3-specific configuration material in JSON representation.

`../bin/configtxgen -printOrg DEArtMSP > ../artifacts/channels/bauhaus.json`

`configtxgen -printOrg Org3MSP > ./channel-artifacts/org3.json`

> This file contains the modification policy definitions for Org3, as well as three important certificates presented in base 64 format: 
> admin user cert,CA root cert and TLS root cert.In an upcoming step we will append this JSON object to the channel configuration.

6. Copy the Orderer Org's MSP material into the Org3 ``crypto-config`` directory. In particular, we are concerned with
the Orderer's TLS root cert, which will allow for secure communication between Org3 entities and the network's ordering node.
`cd newOrg/bauhaus.de/crypto-config`
`cp -r ~/HLF/HyperledgerProjects/artprovenance/config/crypto-config/ordererOrganizations ./`
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

 `export CHANNEL_NAME=mainchannel`

6. Check to make sure the variables have been properly set
`echo $ORDERER_CA && echo $CHANNEL_NAME`

Now we have a running REST server within the CLI container and we have exported our two key environment variables
``ORDERER_CA`` & ``CANNEL_NAME``.

## Form the channel update objects

1. Let's go fetch the most recent config block for the channel - ``mainchannel``.
`peer channel fetch config config_block.pb -o orderer.art.ifar.org:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA`

_The above command applies an arbitrary name - ``config_block.pb`` - to this binary protobuf channel configuration block.  You do have the ability to alter the naming conventions for the returned protobuf and JSON objects, however you should follow an approach that will allow for easy and intuitive identification._

> When you issued the ``peer channel fetch`` command, there was a decent amount of output in the terminal.
> The last line in the logs is of interest:
> ```2017-11-07 17:17:57.383 UTC [channelCmd] readBlock -> DEBU 011 Received block: 2```

> This is telling us that the most recent configuration block for ``mainchannel`` is actually block 2,
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

> copy the bauhaus.json to the channels directory ``generated at Needed House Keeping/step 5``

`jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"DEArtMSP":.[1]}}}}}' config.json ./channels/bauhaus.json >& updated_config.json`

_Now, within the CLI container we have two JSON files of interest - ``config.json`` & ``updated_config.json``.  The initial file contains only Org1 and Org2 material, whereas the aptly named "updated config" file contains all three orgs.  At this point it's simply a matter of re-encoding these two JSON files and calculating the delta._

1. First, encode ``config.json`` to ``config.pb``
`curl -X POST --data-binary @config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > config.pb`

2. encode ``updated_config.json`` to ``updated_config.pb``
`curl -X POST --data-binary @updated_config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > updated_config.pb`

3. use the ``configtxlator`` server to calculate the delta between these two config protos.  This command will output a new protobuf binary named - ``config_update.pb``
`curl -X POST -F channel=$CHANNEL_NAME -F "original=@config.pb" -F "updated=@updated_config.pb" "${CONFIGTXLATOR_URL}/configtxlator/compute/update-from-configs" > config_update.pb`

_This new proto contains the Org3 definitions and high level pointers to the Org1 and Org2 material.  We are able to forgo the extensive MSP material and modification policy information for Orgs 1 and 2, because this data is already present within the channel's genesis block.  As such, we only need the delta between the two configurations._

## Before submitting the channel update, we need to perform a few final steps.

1. Decode this object into editable JSON format,
`curl -X POST --data-binary @config_update.pb "$CONFIGTXLATOR_URL/protolator/decode/common.ConfigUpdate" | jq . > config_update.json`

2. Wrap the decoded update file - ``config_update.json`` in an envelope message.
`echo '{"payload":{"header":{"channel_header":{"channel_id":"mainchannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json`

3. Using our properly formed JSON - ``config_update_in_envelope.json`` - we will leverage the ``configtxlator`` tool one last time and convert this object into the fully fledged proto format that Fabric requires:
`curl -X POST --data-binary @config_update_in_envelope.json "$CONFIGTXLATOR_URL/protolator/encode/common.Envelope" > config_update_in_envelope.pb`

Almost done!  We now have a protobuf binary - ``config_update_in_envelope.pb`` - within our CLI container, however we need signatures from the requisite Admin users before we can successfully submit the update.  The modification policy (mod_policy) for our channel is set to the default of "MAJORITY", which means that we need an admin from both of the initial organizations - ``Org1`` & ``Org2`` - to sign off on
this update transaction.  If we fail to obtain these two signatures, then the ordering service will reject the transaction.  First, let's sign this update proto as the Org1 admin.  Remember that the CLI container is bootstrapped with the Org1 MSP material, so we simply need to issue the ``peer channel signconfigtx``

1. `peer channel signconfigtx -f config_update_in_envelope.pb`

2. The final step is to switch the CLI container's identity to reflect the Org2 Admin user.  We do this by exporting the following environment variables:

`export CORE_PEER_LOCALMSPID="FRArtMSP"`
`export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt`
`export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp`
`export CORE_PEER_ADDRESS=peer0.louvre.fr:7051:7051`

3. And lastly we will issue the ``peer channel update`` command.  The Org2 Admin signature will be attached
to this call, so there is no need to manually sign the proto a second time:

> note:: The upcoming update call to the ordering service will undergo a series
> of systematic signature and policy checks.  As such you may find it useful to stream and inspect the ordering node's logs.  From another 
> shell, issue a ``docker logs -f orderer.art.ifar.org`` command to display them.

`peer channel update -f config_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.art.ifar.org:7050 --tls true --cafile $ORDERER_CA`

>You should see a message digest indication similar to the following if your update is successful:
> ```2017-11-07 21:50:17.435 UTC [msp/identity] Sign -> DEBU 00f Sign: digest: 3207B24E40DE2FAB87A2E42BC004FEAA1E6FDCA42977CB78C64F05A88E556ABA```

At this point, the channel configuration has been updated to include our new organization - ``Org3`` - meaning that peers attached to this member can now successfully join the channel.

## Join Org3 to the channel

1. launch the containers for the Org3 peers and an Org3-specific CLI.
`docker-compose -f docker-compose-org3.yaml up -d`

This new compose file has been configured to bridge across our initial network, so the two peers and the CLI container will be able to resolve with the existing peers and ordering node.  

2. With the three new containers now running, exec into the Org3-specific CLI container:

`docker exec -it Org3cli bash`

3. export the two key environment variables - ``ORDERER_CA`` & ``CHANNEL_NAME``
`export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem && export CHANNEL_NAME=mainchannel`

4. Check to make sure the variables have been properly set
`echo $ORDERER_CA && echo $CHANNEL_NAME`

5. let's send a call to the ordering service asking for the genesis block of ``mychannel``.  The ordering service is able to verify the signature attached to this call as a result of our successful channel update.  If Org3 had not been successfully appended to the channel config, then the ordering service would reject this request.
**Use the ``peer channel fetch`` command to retrieve this block**

`peer channel fetch 0 mainchannel.block -o orderer.art.ifar.org:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA`

>note:: Again, you may find it useful to stream the ordering node's logs to reveal the sign/verify logic and policy checks.

>Notice, that we are passing a ``0`` to indicate that we want the first block on the channel's ledger (i.e. the genesis block).  If we simply passed the ``peer channel fetch config`` command, then we would have received block 5 - the updated config with Org3 defined.  However, we can't begin our ledger with a downstream block; rather we need to join with block 0.

6. Issue the ``peer channel join`` command and pass in the genesis block - ``mychannel.block``

`peer channel join -b mainchannel.block`

7. If you want to join the second peer for Org3, export the TLS and ADDRESS variables and reissue the `` peer channel join command``

  `export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt && export CORE_PEER_ADDRESS=peer1.org3.example.com:7051
  peer channel join -b mychannel.block`

  `peer channel join -b mychannel.block`

## Upgrade & invoke

The final piece of the puzzle is to increment the chaincode version and update the endorsement policy to include Org3.  Stay in the Org3 cli container and install the chaincode.  We can cheat a little bit here and jump directly to version 2, because we know that an upgrade is coming

1. `peer chaincode install -n m -v 2.0 -p chaincode/artmanager`

2. Modify the environment variables accordingly and reissue the command if you want to install the
chaincode on the second peer.

3. Now jump back to the original CLI container and install the new version on the Org1 and Org2 peers.  We submitted the channel update call with the Org2 admin identity, so the container is still acting on behalf of ``peer0.org2``

`cd /opt/gopath/src`

`peer chaincode install -n artmanager -v 2.0 -p chaincode/artmanager`

4. Flip to the ``peer0.org1`` identity

`export CORE_PEER_LOCALMSPID="Org1MSP"`
`export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt`
`export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp`
`export CORE_PEER_ADDRESS=peer0.org1.example.com:7051`

5. install again

`cd /opt/gopath/src`

`peer chaincode install -n artmanager -v 2.0 -p chaincode/artmanager`

6. Now we're ready to upgrade the chaincode.  There have been no modifications to the underlying source code, we are simply adding DEArt (Org3) to the endorsement policy for a chaincode - ``artmanager`` - on a channel -``mainchannel``.

> note:: Any identity satisfying the chaincode's instantiation policy can issue
          the upgrade call.  By default, these identities are the channel Admins.

You can see in the above command that we are specifying our new version by means of the ``v`` flag.  You also see that the endorsement policy has been modified to ``-P "OR ('Org1MSP.member','Org2MSP.member','Org3MSP.member')"``, accurately reflecting the addition of Org3 to the policy.

~`peer chaincode upgrade -o orderer.art.ifar.org:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mainchannel -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.member','Org2MSP.member','Org3MSP.member')"`~

`peer chaincode upgrade -o orderer.art.ifar.org:7050 -C mainchannel -n artmanager -v 2.0 -c '{"Args":[""]}' --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -P "OR ('EGArtMSP.member','FRArtMSP.member','DEArtMSP.member')"`

The final area of interest is our constructor request specified with the ``c`` flag.  As with an instantiate call, a chaincode upgrade requires usage of the ``init`` method.  **If** your chaincode requires arguments be passed to the ``init`` method, then you will
need to provide the appropriate key/vals and reinitialize the state.  This is not the recommended practice, because the upgrade submitter could arbitrarily rewrite the world state.  Instead, consider editing the source code to remove the argument dependency, or start with a chaincode that does not require args upon instantiation.

The upgrade call adds a new block - block 6 - to the channel's ledger and allows for the Org3 peers to execute transactions during the endorsement phase.  

7. Hop back to the Org3 CLI container and issue a query for the value of ``a``.  This will take a bit of time because a chaincode image needs to built for the targeted peer, and the container needs to start:

`peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'`

We should see a response of ``Query Result: 90``.  Now issue an invocation to move ``10`` from ``a`` to ``b``

8. Now issue an invocation

`peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}'`


## Conclusion

The reconfiguration process is indeed quite involved, but there is a logical method to the various steps.  The endgame is to form a delta transaction object represented in protobuf binary format and then accrue the requisite number of admin signatures such that the reconfiguration transaction fulfills the channel's modification policy.

The ``configtxlator`` and ``jq`` tools, along with the ever-growing ``peer channel`` commands, provide us with the functionality to accomplish this task.
