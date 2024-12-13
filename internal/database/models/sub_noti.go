package models

import (
	"math/big"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/utils"

)

type SubInfo struct {
	Address      string
	Amount       *big.Int
	Time         uint
	ParentDirect string
	ParentMatrix string `json"parent_matrix"`
}

type EBuyProductData struct {
	Add        string `json"address"`
	Quantities []int
	Prices     []int
	TotalPrice int
	Time 		int
}
type SubInfoHistory struct {
	ID              int    `gorm:"primary_key" json:"id"`
	Address      	string
	Time         	uint
	ParentDirect 	string
	ParentMatrix 	string
	Rankq			uint
	IsActive		uint
	Phone 			string
	Name			string
	TotalBuyCode	uint
}

type EBuyProductDataHistory struct {
	ID              int    `gorm:"primary_key" json:"id"`
	Add        		string `json:"add"`
	TotalPrice 		uint 
	Time 			uint 
}

var FilterCareer = [...]string{utils.Rank, utils.Status, utils.MinAmount, utils.MaxAmount, utils.BuyCode}
