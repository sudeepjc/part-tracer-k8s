package parttracer

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type TransactionContextInterface interface {
	contractapi.TransactionContextInterface
}

type TransactionContext struct {
	contractapi.TransactionContext
}