package parttracer

import (
	"fmt"
	"strconv"
	s "strings"
	"time"

	"github.com/golang/protobuf/ptypes"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// PartTrade : Business logic Contract
type PartTrade struct {
	contractapi.Contract
}

// InitLedger : Method to initialize the ledger
func (pt *PartTrade) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("initLedger has been invoked")

	ci, _ := ctx.GetClientIdentity().GetID()
	fmt.Println("ClientIdentity : ", ci)

	msp, _ := ctx.GetClientIdentity().GetMSPID()
	fmt.Println("MSPID : ", msp)

	tx := ctx.GetStub().GetTxID()
	fmt.Println("TXID : ", tx)

	chanl := ctx.GetStub().GetChannelID()
	fmt.Println("ChannelID : ", chanl)

	tim, _ := ctx.GetStub().GetTxTimestamp()

	txTime, _ := ptypes.Timestamp(tim)

	PartID := s.Join([]string{"pName", txTime.Format("2006-01-02_5:04:05")}, "_")

	fmt.Println("Tx timestamp : ", PartID)

	return nil
}

// AddPart : Method to add a part to the ledger
func (pt *PartTrade) AddPart(ctx contractapi.TransactionContextInterface, partID string, pName string, desc string, qprice uint32, maker string) (string, error) {

	if len(partID) == 0 {
		return "", fmt.Errorf("Invalid part ID")
	}

	if len(pName) == 0 {
		return partID, fmt.Errorf("Invalid part Name info")
	}

	if len(desc) == 0 {
		return partID, fmt.Errorf("Invalid description ")
	}

	if len(maker) == 0 {
		return partID, fmt.Errorf("Invalid manufacturer info")
	}

	if qprice <= 0 {
		return partID, fmt.Errorf("Invalid quote price info")
	}

	status, _ := checkEligibility(ctx, "general.manufacturing")

	if !status {
		return partID, fmt.Errorf("User should be from Manufacturing department")
	}

	// check if the part exists already and throw an error if it is so
	partAsBytes, err := ctx.GetStub().GetState(partID)

	if err != nil {
		return partID, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if partAsBytes != nil {
		return partID, fmt.Errorf("%s : already exists", partID)
	}

	owner, _ := ctx.GetClientIdentity().GetMSPID()

	// partID := s.Join([]string{pName,currentTime.Format("2006-01-02_5:04:05")},"_")
	part := Part{ObjectType: "Part", PartID: partID, PartName: pName, Description: desc, QuotePrice: qprice, Manufacturer: maker, Owner: owner}
	part.SetNew()

	// use tx time for deterministic behavior of the execution
	// tim, _ := ctx.GetStub().GetTxTimestamp()
	// txTime, _ := ptypes.Timestamp(tim)
	txTime := time.Now()
	part.EventTime = txTime.Format("2006-01-02_5:04:05")

	partAsBytes, err = part.Serialize()

	if err != nil {
		return partID, fmt.Errorf("Failed to add part while serializing data %s", err.Error())
	}

	fmt.Println("added part ", partID)

	err = ctx.GetStub().PutState(partID, partAsBytes)

	if err != nil {
		return partID, fmt.Errorf("Error while trying to add sell data to state: %s", err.Error())
	}

	eventPayload := "{\"partID\":\"" + partID + "\", \"by\":\"" + maker + "\",\"amount\":" + strconv.FormatInt(int64(qprice), 10) + "}"
	ctx.GetStub().SetEvent("addPart", []byte(eventPayload))

	return partID, err
}

// QueryPart : Method to query the part given the partID
func (pt *PartTrade) QueryPart(ctx contractapi.TransactionContextInterface, partID string) (*Part, error) {

	if len(partID) == 0 {
		return nil, fmt.Errorf("Invalid part ID")
	}

	partAsBytes, err := ctx.GetStub().GetState(partID)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if partAsBytes == nil {
		return nil, fmt.Errorf("%s : does not exist", partID)
	}

	part := new(Part)
	_ = Deserialize(partAsBytes, part)

	return part, nil
}

// SellPart : Method to sell the part if the conditions meet
func (pt *PartTrade) SellPart(ctx contractapi.TransactionContextInterface, partID string, buyer string, dprice uint32) (*Part, error) {

	if len(partID) == 0 {
		return nil, fmt.Errorf("Invalid part ID")
	}

	if dprice <= 0 {
		return nil, fmt.Errorf("Invalid dprice")
	}

	partAsBytes, err := ctx.GetStub().GetState(partID)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if partAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", partID)
	}

	part := new(Part)
	_ = Deserialize(partAsBytes, part)

	seller, _ := ctx.GetClientIdentity().GetMSPID()

	if part.Owner != seller {
		return nil, fmt.Errorf("Part %s is not owned by %s", partID, seller)
	}

	department := "general.sales.sharks"

	discount := part.QuotePrice - dprice

	percentageDiscount := (discount * 100) / part.QuotePrice

	fmt.Println("percentageDiscount: ", percentageDiscount)

	if percentageDiscount > 10 {
		department = "general.sales.mgrs"
	}

	status, _ := checkEligibility(ctx, department)

	if !status {
		return nil, fmt.Errorf("User should be from %s department", department)
	}

	if part.IsNew() {
		part.SetUsed()
	}

	tim, _ := ctx.GetStub().GetTxTimestamp()
	txTime, _ := ptypes.Timestamp(tim)
	part.EventTime = txTime.Format("2006-01-02_5:04:05")

	part.SetOwner(buyer)
	part.DealPrice = dprice

	updatedPartAsBytes, err := part.Serialize()

	if err != nil {
		return nil, fmt.Errorf("Failed to update part while serializing data %s", err.Error())
	}

	fmt.Println("updated part ", partID)

	err = ctx.GetStub().PutState(partID, updatedPartAsBytes)

	if err != nil {
		return nil, fmt.Errorf("Error while trying to add sell data to state: %s", err.Error())
	}

	eventPayload := "{\"partID\":\"" + partID + "\", \"buyer\":\"" + buyer + "\",\"amount\":" + strconv.FormatInt(int64(dprice), 10) + "}"
	ctx.GetStub().SetEvent("sellPart", []byte(eventPayload))

	return part, nil
}

// QueryParts : Method to query the parts in the given range
func (pt *PartTrade) QueryParts(ctx contractapi.TransactionContextInterface, startKey string, endKey string) ([]QueryResult, error) {

	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
		return nil, err
	}

	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		part := new(Part)
		_ = Deserialize(queryResponse.Value, part)

		queryResult := QueryResult{Key: queryResponse.Key, Record: part}
		results = append(results, queryResult)
	}
	return results, nil
}

// QueryPartsWithPagination : Method to query the parts in the given range with Pagination
func (pt *PartTrade) QueryPartsWithPagination(ctx contractapi.TransactionContextInterface, startKey string, endKey string, pageSize int32, bookmark string) (*PagedQueryResult, error) {

	if pageSize <= 1 {
		return nil, fmt.Errorf("Error with the pagesize, should be greater than 1")
	}

	resultsIterator, responseMetadata, err := ctx.GetStub().GetStateByRangeWithPagination(startKey, endKey, int32(pageSize), bookmark)

	if err != nil {
		return nil, err
	}

	defer resultsIterator.Close()

	pResults := new(PagedQueryResult)

	pResults.Record = []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		part := new(Part)
		_ = Deserialize(queryResponse.Value, part)

		queryResult := QueryResult{Key: queryResponse.Key, Record: part}
		pResults.Record = append(pResults.Record, queryResult)
	}

	pResults.Count = strconv.FormatInt(int64(responseMetadata.FetchedRecordsCount), 10)
	pResults.BookMark = responseMetadata.GetBookmark()

	return pResults, nil
}

// GetPartHistory : Fetches the history of the part given the partID
func (pt *PartTrade) GetPartHistory(ctx contractapi.TransactionContextInterface, partID string) ([]HistoryResult, error) {

	if len(partID) == 0 {
		return nil, fmt.Errorf("Invalid part ID")
	}

	fmt.Printf("- start getHistoryForMarble: %s\n", partID)

	historyIterator, err := ctx.GetStub().GetHistoryForKey(partID)

	if err != nil {
		return nil, err
	}

	defer historyIterator.Close()

	results := []HistoryResult{}

	for historyIterator.HasNext() {
		response, err := historyIterator.Next()
		if err != nil {
			return nil, err
		}

		historyResult := new(HistoryResult)
		historyResult.TxID = response.TxId
		historyResult.TimeStamp = time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String()
		historyResult.IsDelelted = strconv.FormatBool(response.IsDelete)

		if response.IsDelete {
			historyResult.Record = new(Part)
		} else {
			part := new(Part)
			_ = Deserialize(response.Value, part)
			historyResult.Record = part
		}
		results = append(results, *historyResult)
	}

	return results, nil
}

// DeletePart : Is going to delete the part from the state database
func (pt *PartTrade) DeletePart(ctx contractapi.TransactionContextInterface, partID string) error {

	if len(partID) == 0 {
		return fmt.Errorf("Invalid part ID")
	}

	partAsBytes, err := ctx.GetStub().GetState(partID)

	if err != nil {
		return fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if partAsBytes == nil {
		return fmt.Errorf("%s does not exist", partID)
	}

	err = ctx.GetStub().DelState(partID)

	if err != nil {
		return fmt.Errorf("Error while deleting the Part: %s", err.Error())
	}

	return nil
}

// GetRichQueryResult : Gets the query results based on User Query
func (pt *PartTrade) GetRichQueryResult(ctx contractapi.TransactionContextInterface, query string) ([]QueryResult, error) {

	if len(query) == 0 {
		return nil, fmt.Errorf("Empty Query sent")
	}

	resultsIterator, err := ctx.GetStub().GetQueryResult(query)

	if err != nil {
		return nil, err
	}

	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			return nil, err
		}

		part := new(Part)
		_ = Deserialize(queryResponse.Value, part)

		queryResult := QueryResult{Key: queryResponse.Key, Record: part}
		results = append(results, queryResult)
	}
	return results, nil
}

func checkEligibility(ctx contractapi.TransactionContextInterface, department string) (bool, error) {

	affiliation, found, err := ctx.GetClientIdentity().GetAttributeValue("hf.Affiliation")

	if err != nil {
		return false, err
	}

	if found == true {
		if affiliation == department {

			return true, nil
		} else {
			return false, nil
		}
	} else {
		return false, nil
	}

}