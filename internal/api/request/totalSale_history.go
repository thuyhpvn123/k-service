package request

type QueryEBuyHistoryRequest struct {
	Address string `form:"address"`
}
type QueryEBuyHistoryByTimeRequest struct {
	Address string `form:"address"`
	From int `form:"from"`
	To int `form:"to"`
	Filter int `form:"filter"`
}