package request

type QueryBonusHistoryRequest struct {
	Type    string `form:"type"`
	Address string `form:"address"`
}
type QueryBonusHistoryByTimeRequest struct {
	Type    string `form:"type"`
	Address string `form:"address"`
	From    int    `form:"from"`
	To      int    `form:"to"`
}

type InsertBatchBonusHistory struct {
	BlockCount      string `json:"block_count"`
	TransactionHash string `json:"transaction_hash"`
	LogHash         string `json:"log_hash"`
	Data            string `json:"data"`
}
