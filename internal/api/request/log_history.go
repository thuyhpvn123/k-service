package request

type LogInRequest struct {
	Address string `json:"address"`
	TimeLogIn uint `json:"time_login"`
}
type LogOutRequest struct {
	Address string `json:"address"`
	TimeLogOut uint `json:"time_logout"`
}
// type QueryBonusHistoryByTimeRequest struct {
// 	Type    string `form:"type"`
// 	Address string `form:"address"`
// 	From int `form:"from"`
// 	To int `form:"to"`
// }