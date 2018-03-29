package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	"encoding/json"
	"fmt"
	"strings"
	"bytes"
)

//contain the structure for the chaincode/implements ChaincodeStubInterface
type TransferManager struct {
}

type Artifact struct {
	ObjectType string `json:"docType"`
	ID         string `json:"id"`     //unique string used as Artifact key
	Desc       string `json:"desc"`   //string description of Artifact
	Status     string `json:"status"` //stolen|clear|...
	Owner      string `json:"owner"`  //current owner
}

var logger = shim.NewLogger("artifact_transfer")

const invalidFunction = "invalid chaincode function"
const docType = "artifact"

// ============================================================
//
// ============================================================
func main() {
	err := shim.Start(new(TransferManager))
	if err != nil {
		logger.Errorf("error starting chaincode: %s", err)
	}
}

// ============================================================
// function Init is called during the chaincode instantiation to initialize any data
// ============================================================
func (t *TransferManager) Init(stub shim.ChaincodeStubInterface) pb.Response {
	// for instantiation will provide a separate function
	return shim.Success(nil)
}

// ============================================================
//
// ============================================================
func (t *TransferManager) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Infof("Invoke is running...")
	// retrieve chaincode function and arguments
	fn, args := stub.GetFunctionAndParameters()
	logger.Info("Function name: " + fn)
	// choose appropriate function to handle invoke
	switch fn {
	case "create":
		return t.create(stub, args)
	case "transferOwner":
		return t.transferOwner(stub, args)
	case "setStatus":
		return t.setStatus(stub, args)
	case "queryByOwner":
		return t.queryByOwner(stub, args)
	case "read":
		return t.read(stub, args)
	default:
		return shim.Error(invalidFunction)
	}

	return shim.Error(invalidFunction)
}

// ============================================================
// create - create a new artifact, store into chaincode state
// arguments : [artifactId, description, status, owner]
// ============================================================
func (t *TransferManager) create(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var err error

	if len(args) != 4 {
		return shim.Error("incorrect number of arguments;expecting [artifactId, description, status, owner]")
	}

	id := strings.ToLower(args[0])
	desc := strings.ToLower(args[1])
	status := strings.ToLower(args[2])
	owner := strings.ToLower(args[3])

	//check if artifact already exists
	artifactAsBytes, err := stub.GetState(id)
	if err != nil {
		return shim.Error("failed to find existing artifact: " + err.Error())
	} else if artifactAsBytes != nil {
		return shim.Error("artifact already exist: " + err.Error())
	}

	// create artifact object and marshal to json

	artifact := &Artifact{
		ObjectType: docType,
		ID:         id,
		Desc:       desc,
		Status:     status,
		Owner:      owner,
	}

	artifactJsonAsBytes, err := json.Marshal(artifact)
	if err != nil {
		return shim.Error(err.Error())
	}

	//save to state db
	err = stub.PutState(id, artifactJsonAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	//=======Index the artifacts to enable owner range queries
	//  An 'index' is a normal key/value entry in state.
	//  The key is a composite key, with the elements that you want to range query on listed first.
	//  In our case, the composite key is based on indexName~owner~id.
	//  This will enable very efficient state range queries based on composite keys matching indexName~color~*
	indexName := "owner~id"
	ownerIdIndexKey, err := stub.CreateCompositeKey(indexName, []string{artifact.Owner, artifact.ID})
	if err != nil {
		return shim.Error(err.Error())
	}

	//  Save index entry to state. Only the key owner is needed, no need to store a duplicate copy of the artifact.
	//  Note - passing a 'nil' value will effectively delete the key from state, therefore we pass null character as value
	value := []byte{0x00}
	stub.PutState(ownerIdIndexKey, value)

	// ==== Artifact saved and indexed. Return success ====
	fmt.Println("- end init artifact")
	logger.Info([]byte(fmt.Sprintf("artifact {%v} added", artifact)))
	return shim.Success(nil)
}

//====== Example: change attribute =========================================================
// transferOwner changes ownership of artifact
// required arguments : artifact id, new owner
// =========================================================================================
func (t *TransferManager) transferOwner(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error
	if len(args) < 2 {
		return shim.Error("incorrect number of arguments;expecting [artifact id,new owner]")
	}

	id := strings.ToLower(args[0])
	artifactAsBytes, err := stub.GetState(id)
	if err != nil {
		return shim.Error("failed to find existing artifact: " + err.Error())
	} else if artifactAsBytes == nil {
		return shim.Error("failed to find existing artifact: " + err.Error())
	}

	newOwner := strings.ToLower(args[1])

	artifact := Artifact{}
	err = json.Unmarshal(artifactAsBytes, &artifact)
	if err != nil {
		return shim.Error(err.Error())
	}
	artifact.Owner = newOwner

	artifactJSONAsBytes, _ := json.Marshal(artifact)
	err = stub.PutState(id, artifactJSONAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	logger.Info("artifact owner changed")
	return shim.Success(nil)
}

// ============================================================
// setStatus
// ============================================================
func (t *TransferManager) setStatus(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var err error

	if len(args) < 2 {
		return shim.Error("incorrect number of arguments;expecting [artifact id,new status]")
	}

	id := strings.ToLower(args[0])
	newStatus := strings.ToLower(args[1])

	artifactAsBytes, err := stub.GetState(id)
	if err != nil {
		return shim.Error("failed to find existing artifact: " + err.Error())
	}

	artifact := Artifact{}
	err = json.Unmarshal(artifactAsBytes, &artifact)
	if err != nil {
		return shim.Error(err.Error())
	}
	artifact.Status = newStatus

	artifactJSONAsBytes, err := json.Marshal(artifact)
	if err!= nil{
		return shim.Error(err.Error())
	}

	err = stub.PutState(id, artifactJSONAsBytes)
	if err!= nil{
		return shim.Error(err.Error())
	}

	logger.Info("artifact status changed")
	return shim.Success(nil)
}

// ===== Example: Ad hoc rich query ========================================================
// queryMarbles uses a query string to perform a query for marbles.
// Query string matching state database syntax is passed in and executed as is.
// Supports ad hoc queries that can be defined at runtime by the client.
// If this is not desired, follow the queryMarblesForOwner example for parameterized queries.
// Only available on state databases that support rich query (e.g. CouchDB)
// =========================================================================================
func (t *TransferManager) queryByOwner(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) < 1 {
		return shim.Error("incorrect number of arguments;expecting one [owner]")
	}

	owner := strings.ToLower(args[0])
	queryString := fmt.Sprintf("{\"selector\":{\"docType\":\"%s\",\"owner\":\"%s\"}}", docType, owner)

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

// =========================================================================================
// getQueryResultForQueryString executes the passed in query string.
// Result set is built and returned as a byte array containing the JSON results.
// =========================================================================================
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryRecords
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

// ============================================================
// read
// ============================================================
func (t *TransferManager) read(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var id, jsonResp string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting id of the artifact to query")
	}

	id = args[0]
	valAsbytes, err := stub.GetState(id) //get the artifact from chaincode state
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + id + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"Marble does not exist: " + id + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}
