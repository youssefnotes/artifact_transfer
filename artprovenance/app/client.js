'use strict'

const hfc = require('fabric-client');
let channel;

const enrollUser = function (client, options) {
    return hfc.newDefaultKeyValueStore({path: options.wallet_path})
        .then(wallet => {
            client.setStateStore(wallet);
            return client.getUserContext(options.user_id, true);
        });
};


const initNetwork = function (client, options, target) {
    let channel;
    try {
        channel = client.newChannel(options.channel_id);
        const peer = client.newPeer(options.peer_url);
        target.push(peer);
        channel.addPeer(peer);
        channel.addOrderer(client.newOrderer((options.orderer_url)));
    } catch (e) {
        channel = client.getChannel(options.channel_id);
    }
    return channel
};

const transactionProposal = function (client, channel, request) {
    request.tx_id = client.newTransactionID();
    return channel.sendTransactionProposal(request);
};

const responseInspect = function (results) {
    if (results[0] && results[0].length > 0 &&
        results[0][0].response && results[0][0].response.status === 200) {
        return true;
    }
    return false;
};

const sendOrderer = function (channel, request) {
    return channel.sendTransaction(request);
};

const target = [];
const client = new hfc();

function invoke(opt, param) {
    return enrollUser(client, opt)
        .then(user => {
            if (typeof user === "undefined" || !user.isEnrolled()) {
                throw "User not enrolled";
            }
            channel = initNetwork(client, opt, target);
            const request = {
                targets: target,
                chaincodeId: opt.chaincode_id,
                fcn: 'create',
                args: param,
                chainId: opt.channel_id,
                txId: null
            };
            return transactionProposal(client, channel, request);
        })
        .then(results => {
            if (responseInspect(results)) {
                const request = {
                    proposalResponses: results[0],
                    proposal: results[1],
                    header: results[2]
                };
                return sendOrderer(channel, request);
            } else {
                throw "Bad Response";
            }
        })
        .catch(err => {
            console.log(err);
            throw err;
        })
}

const options = {
    egyptianmuseum: {
        wallet_path: './certs',
        user_id: 'EGArtAdmin',
        channel_id: 'mainchannel',
        chaincode_id: 'artifact_transfer',
        peer_url: 'grpc://localhost:7051',
        orderer_url: 'grpc://localhost:7050'
    }
};


const express = require("express");
const app = express();
const http = require("http");
const bodyParser = require("body-parser");

const server = http.createServer(app).listen(4000, function () {
});

app.use(bodyParser.json());

app.post('/invoke', function (req, res, next) {
    const args = req.body.args;
    invoke(options[args[0]], args.slice(1))
        .then(() => {
            res.send("Chaincode invoked")
        })
        .catch(err => {
            res.status(500);
            res.send(err.toString());
        })
})