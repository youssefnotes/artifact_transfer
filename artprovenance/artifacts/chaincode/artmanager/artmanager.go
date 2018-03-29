package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
	"fmt"
	"time"
	"strconv"
)

type ArtifactManager struct {
}

type artifact struct {
	Owner     string
	ID        string
	Quantity  string
	TimeStamp string
}

var logger = shim.NewLogger("artmanager")

const unknownfunction = "available functions to use: addNewArtifact|queryArtifactDetails|" +
	"updateArtifact|transferArtifact "

// function Init is called during the chaincode instantiation to initialize any data
func (t *ArtifactManager) Init(stub shim.ChaincodeStubInterface) pb.Response {
	//incase of migration steps
	//they are added here
	//args := stub.GetStringArgs()
	//if len(args) != 2 {
	//	return shim.Error("expected key:value argument")
	//}
	//err:= stub.PutState(args[0],[]byte(args[1]))
	//if err != nil{
	//	return shim.Error(fmt.Sprintf("failed to create artifact: %s",args[0]))
	//}
	return shim.Success(nil)
}

func (t *ArtifactManager) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("##########Artifact Manager###########")
	fn, args := stub.GetFunctionAndParameters()
	logger.Info(fn)
	switch fn {
	case "addNewArtifact":
		logger.Info("Executing addNewArtifact")
		return t.addNewArtifact(stub, args)
	case "queryArtifactDetails":
		logger.Info("Executing queryArtifactDetails")
		return t.queryArtifactDetails(stub, args)
	case "updateArtifact":
		logger.Info("Executing updateArtifact")
		return t.updateArtifact(stub, args)
	case "transferArtifact":
		logger.Info("Executing transferArtifact")
		return t.transferArtifact(stub, args)
	case "testClientCall":
		return t.testClientCall()
	default:
		logger.Info(unknownfunction)
		return shim.Error(unknownfunction)
	}
	//logger.Info(unknownfunction)
	return shim.Error(unknownfunction)
}
func (t *ArtifactManager) testClientCall() pb.Response {
	return shim.Success([]byte("OK! Client Call success"))
}

//transferArtifact handles the change of ownership to an already owned artifact
//it accepts 4 arguments : currentOwner,newOwner,id of artifact,transferable quantity
func (t *ArtifactManager) transferArtifact(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 4 {
		return shim.Error("transferArtifact arguments: currentOwner,newOwner,id,qty")
	}
	currentOwner := args[0]
	newOwner := args[1]
	id := args[2]
	qty := args[3]
	// the key consists from currentOwner + artifact id
	key := currentOwner + id
	//getting current owner artifact ownership record to be processed
	artifactBytes, err := stub.GetState(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	var currentOwnerArtifact artifact

	err = json.Unmarshal(artifactBytes, currentOwnerArtifact)
	if err != nil {
		return shim.Error(err.Error())
	}
	//parsing current owner quantity
	currentOwnerQty, err := strconv.Atoi(currentOwnerArtifact.Quantity)
	//transferableQty quantity
	transferableQty, err := strconv.Atoi(qty)
	//calculating current owner new balance(holding)
	currentOwnerQty -= transferableQty
	currentOwnerArtifact.Quantity = strconv.Itoa(currentOwnerQty)
	artifactBytes, err = json.Marshal(currentOwnerArtifact)
	stub.PutState(key, artifactBytes)
	//Preparing new Owner artifact balance
	key = newOwner + id
	if artifactBytes, err = stub.GetState(key); artifactBytes == nil || err != nil {
		logger.Info("new account/artifact, %v", err.Error())
		//handle adding new
		t.addNewArtifact(stub, args)
		return shim.Success(nil)
	}
	var newOwnerArtifact artifact
	err = json.Unmarshal(artifactBytes, newOwnerArtifact)
	if err != nil {
		shim.Error(err.Error())
	}
	currentOwnerQty, err = strconv.Atoi(newOwnerArtifact.Quantity)
	currentOwnerQty += transferableQty
	newOwnerArtifact.Quantity = strconv.Itoa(currentOwnerQty)
	artifactBytes, err = json.Marshal(newOwnerArtifact)
	err = stub.PutState(key, artifactBytes)
	if err != nil {

	}
	return shim.Success(nil)
}

func (t *ArtifactManager) addNewArtifact(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 3 {
		return shim.Error("addNewArtifact arguments usage: Organization, ID, Quantity")
	}
	// A newly created artifact is available
	art := artifact{
		Owner:     args[0],
		ID:        args[1],
		Quantity:  args[2],
		TimeStamp: time.Now().String()}
	// Use JSON to store in the Blockchain
	var key string = art.Owner + art.ID
	if fnd, err := stub.GetState(key); fnd != nil || err != nil {
		return shim.Error("artifact exist already.")
	}
	availableBytes, _ := json.Marshal(art)
	err := stub.PutState(key, availableBytes)
	if err != nil { //not found
		return shim.Error("can't add artifact")
	}
	return shim.Success([]byte(fmt.Sprintf("artifact %v added", art)))
}

func (t *ArtifactManager) queryArtifactDetails(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 2 {
		return shim.Error("parameter mismatch (org,id)")
	}

	key := args[0] + args[1]
	availableBytes, err := stub.GetState(key)

	if err != nil {
		return shim.Error(err.Error())
	}

	var art artifact
	json.Unmarshal(availableBytes, &art)

	return shim.Success([]byte (fmt.Sprintf("Org: %v,ID: %v,Quantity: %v,Time: %v",
		art.Owner, art.ID, art.Quantity, art.TimeStamp)))
}

func (t *ArtifactManager) updateArtifact(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 4 {
		return shim.Error("parameter mismatch (org,id,quantity,time)")
	}
	var key = args[0] + args[1]
	availableBytes, err := stub.GetState(key)
	if err != nil {
		return shim.Error("artifact doesn't exist")
	}
	var art artifact
	json.Unmarshal(availableBytes, &art)
	art.Quantity = args[2]
	art.TimeStamp = time.Now().String()
	newArtByte, _ := json.Marshal(art)
	err = stub.PutState(key, newArtByte)
	if err != nil {
		return shim.Error("artifact update error")
	}
	return shim.Success([]byte("artifact updated"))
}

func main() {
	err := shim.Start(new(ArtifactManager))
	if err != nil {
		logger.Errorf("error starting chaincode: %s", err)
	}
}
