package request

type QuerySubInfoHistoryRequest struct {
	Address string `form:"parent_direct"`
}
type QuerySubInfoHistoryByTimeRequest struct {
	Address string `form:"parent_direct"`
	From 	int `form:"from"`
	To 		int `form:"to"`
}
type QuerySubInfoHistoryByFilter struct {
	Address 	string `json:"parent_direct"`
	Rank 		[]uint `json:"rankq"`
	Status 		[]uint `json:"status"`
	BuyCode		string`json:"buy_code"`
	MinAmount	int `json:"min_amount"`
	MaxAmount 	int `json:"max_amount"`
}