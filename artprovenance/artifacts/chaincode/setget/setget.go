package main

import (
    "fmt"
    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type SetGetChaincode struct { // define to implement CC interface
}

func main() {
    err := shim.Start(new(SetGetChaincode))
    if err != nil {
        fmt.Printf("Error starting first chaincode sample: %s", err)
    }
}

func (t *SetGetChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response { // implement Init
    return shim.Success(nil)
}

// Implement Invoke
func (t *SetGetChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    fmt.Println("Start Invoke")
    defer fmt.Println("Stop Invoke")

    // Get function name and args
    function, args := stub.GetFunctionAndParameters()

    if function == "set" {
        // The peer invoked set
        if len(args) != 2 {
            // We cannot proceed without both a key and a value
            return shim.Error("Expecting 2 arguments")
        }
        // put key,value in writeset
        err := stub.PutState(args[0], []byte(args[1]))
        if err != nil {
            return shim.Error(err.Error())
        }
        return shim.Success(nil)
    } else if function == "get" {
        // The peer invoked get
        if len(args) != 1 {
            // We cannot proceed without a key
            return shim.Error("Expecting key")
        }
        // Look up into readset
        v, err := stub.GetState(args[0])
        // Not on my watch!
        if err != nil {
            return shim.Error("Failed to get state for " + args[0])
        }

        fmt.Printf("Get Response for key %v is %v\n", args[0], v)
        return shim.Success(v)
    }

    return shim.Error("Invalid invoke function name.")
}