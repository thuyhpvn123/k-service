package models

type BonusHistory struct {
	ID              int    `gorm:"primary_key" json:"id"`
	Address         string `json:"address"`
	Amount          uint64 `json:"amount"`
	Time            uint   `json:"time"`
	Type            string `json:"type"`
	Rank            uint   `json:"rank"`
	Index           uint   `json:"index"`
	Rate            uint   `json:"rate"`
	BlockCount      string `json:"block_count"`
	TransactionHash string `json:"transaction_hash"`
	LogHash         string `json:"log_hash"`
}

type DiscountHistory struct {
	ID       int    `gorm:"primary_key" json:"id"`
	Address  string `json:"address"`
	Link     string
	Percent  uint
	Discount uint
	Time     uint
}
