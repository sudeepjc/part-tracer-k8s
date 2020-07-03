package main

import (
	"fmt"
	"simple/parttracer"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {

	contract := new(parttracer.PartTrade)
	contract.TransactionContextHandler = new(parttracer.TransactionContext)
	contract.Name = "org.partTracer.partTrade"
	contract.Info.Version = "0.0.1"

	chaincode, err := contractapi.NewChaincode(contract)

	if err != nil {
		panic(fmt.Sprintf("Error creating chaincode. %s", err.Error()))
	}

	chaincode.Info.Title = "PartTradeChaincode"
	chaincode.Info.Version = "0.0.1"

	err = chaincode.Start()

	if err != nil {
		panic(fmt.Sprintf("Error starting chaincode. %s", err.Error()))
	}

}