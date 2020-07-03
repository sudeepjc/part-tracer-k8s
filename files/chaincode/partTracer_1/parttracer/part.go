package parttracer

import (
	"encoding/json"
	"fmt"
)

type State uint

const (
	NEW State = iota + 1
	USED
	REFURBISHED
)

func (state State) String() string {
	names := []string{"NEW", "USED", "REFURBISHED"}

	if state < NEW || state > REFURBISHED {
		return "UNKNOWN"
	}

	return names[state-1]
}

type Part struct {
	ObjectType   string `json:"docType"`
	PartID       string `json:"partId"`
	PartName     string `json:"partName"`
	Description  string `json:"description"`
	QuotePrice   uint32 `json:"quotePrice"`
	Manufacturer string `json:"manufacturer"`
	Owner        string `json:"owner"`
	DealPrice    uint32 `json:"dealPrice"`
	EventTime    string `json:"eventTime"`
	Condition    State  `json:"condition"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"key"`
	Record *Part
}

// PagedQueryResult structure used for handling result of query
type PagedQueryResult struct {
	Count    string `json:"count"`
	BookMark string `json:"bookMark"`
	Record   []QueryResult
}

// HistoryResult structure used for handling result of query
type HistoryResult struct {
	TxID       string `json:"txID"`
	Record     *Part
	TimeStamp  string `json:timeStamp`
	IsDelelted string `json:isDeleted`
}

func (p *Part) SetDealPrice(price uint32) {
	p.DealPrice = price
}

func (p *Part) SetOwner(newOwner string) {
	p.Owner = newOwner
}

func (p *Part) GetCondition() State {
	return p.Condition
}

func (p *Part) SetNew() {
	p.Condition = NEW
}

func (p *Part) SetUsed() {
	p.Condition = USED
}

func (p *Part) SetRefurbished() {
	p.Condition = REFURBISHED
}

func (p *Part) IsNew() bool {
	return p.Condition == NEW
}

func (p *Part) IsUsed() bool {
	return p.Condition == USED
}

func (p *Part) IsRefurbished() bool {
	return p.Condition == REFURBISHED
}

func (p *Part) Serialize() ([]byte, error) {
	return json.Marshal(p)
}

func Deserialize(bytes []byte, p *Part) error {
	err := json.Unmarshal(bytes, p)

	if err != nil {
		return fmt.Errorf("Error deserializing part. %s", err.Error())
	}

	return nil
}